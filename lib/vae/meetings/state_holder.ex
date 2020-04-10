defmodule Vae.Meetings.StateHolder do
  require Logger
  use GenServer

  alias Vae.Meetings.{Delegate, Meeting}
  alias Vae.Search.Client.Algolia, as: AlgoliaClient
  alias Vae.Places

  @name StateHolder

  @doc false
  def start_link() do
    start_link([])
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: StateHolder)
  end

  @impl true
  def init(_state) do
    state =
      PersistentEts.new(:meetings, "priv/tabs/meetings.tab", [:named_table, :public])
      |> from_ets()

    {:ok, state}
  end

  def handle_cast({:save, name, delegate}, state) do
    new_state =
      state
      |> Enum.find_index(fn del ->
        del.name == name
      end)
      |> case do
        nil ->
          with parsed_delegate <- delegate |> parse(name),
               {:ok, delegate} <- index_and_persist(parsed_delegate, name) do
            [
              delegate
              | state
            ]
          else
            {:error, msg} ->
              Logger.error(fn -> inspect(msg) end)
              state
          end

        index ->
          stated_delegate = Enum.at(state, index)

          parsed_delegate =
            delegate
            |> parse(name)

          updated_delegate =
            if stated_delegate.req_id == parsed_delegate.req_id do
              case parsed_delegate do
                %Delegate{meetings: []} ->
                  stated_delegate

                parsed_delegate ->
                  %Delegate{
                    stated_delegate
                    | grouped_meetings:
                        parsed_delegate.grouped_meetings ++ stated_delegate.grouped_meetings,
                      indexed_meetings:
                        parsed_delegate.indexed_meetings ++ stated_delegate.indexed_meetings,
                      meetings: parsed_delegate.meetings ++ stated_delegate.meetings
                  }
              end
            else
              Map.merge(stated_delegate, parsed_delegate)
            end

          with {:ok, delegate} <- index_and_persist(updated_delegate, name),
               new_state <- List.delete_at(state, index) do
            [
              delegate
              | new_state
            ]
          else
            {:error, msg} ->
              Logger.error(fn -> inspect(msg) end)
              state
          end
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:subscribe, name}, state) do
    Logger.info(fn -> "#{name} subscribed" end)

    case :ets.lookup(:meetings, name) do
      [] ->
        GenServer.cast(name, {:fetch, self(), Delegate.new(name)})

      [{_delegate_name, updated_at, _grouped_meetings}] ->
        case DateTime.compare(
               Timex.add(updated_at, Timex.Duration.from_hours(48)),
               DateTime.utc_now()
             ) do
          :lt ->
            GenServer.cast(name, {:fetch, self(), Delegate.new(name)})

          _ ->
            nil
        end
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:fetch, name}, state) do
    GenServer.cast(name, {:fetch, self(), Delegate.new(name)})
    {:noreply, state}
  end

  @impl true
  def handle_cast(:fetch_all, state) do
    :ets.tab2list(:meetings)
    |> Enum.each(fn {name, _dt, _meetings} ->
      GenServer.cast(name, {:fetch, self(), Delegate.new(name)})
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call(:all, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:get, nil}, _from, state) do
    {:reply, [], state}
  end

  @impl true
  def handle_call({:get, delegate}, _from, state) do
    AlgoliaClient.get_meetings(delegate)
    |> handle_meetings_result(state)
  end

  @impl true
  def handle_call({:get_by_meeting_id, nil}, _from, state) do
    {:reply, %Meeting{}, state}
  end

  @impl true
  def handle_call({:get_by_meeting_id, meeting_id}, _from, state) do
    meeting =
      state
      |> from_delegates()
      |> Enum.flat_map(& &1[:meetings])
      |> Enum.find(fn meeting -> meeting.meeting_id == meeting_id end)

    {:reply, meeting, state}
  end

  @impl true
  def handle_call({:register, {%{name: name} = meeting, application}}, _from, state) do
    with {:ok, _registered_meeting} <-
           GenServer.call(name, {:register, {meeting, application}}) do
      {:reply, {:ok, meeting}, state}
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        {:reply, {:error, meeting}, state}
    end
  end

  def safe_send_to_genserver(method, params) do
    try do
      apply(GenServer, method, [
        @name,
        params
      ])
    catch
      :exit, {:noproc, _infos} ->
        Logger.warn(
          "Meetings process not available. Set ALGOLIA_MEETINGS_INDICE environment variable."
        )

        []
    end
  end

  def subscribe(who) do
    safe_send_to_genserver(:cast, {:subscribe, who})
    # GenServer.cast(@name, {:subscribe, who})
  end

  def save(name, data) do
    safe_send_to_genserver(:cast, {:save, name, data})
    # GenServer.cast(@name, {:save, name, data})
  end

  def all() do
    safe_send_to_genserver(:call, :all)
    # GenServer.call(@name, :all)
  end

  def get(delegate) do
    safe_send_to_genserver(:call, {:get, delegate})
  end

  def get_by_meeting_id(meeting_id) do
    GenServer.call(@name, {:get_by_meeting_id, meeting_id})
  end

  def fetch(name) do
    GenServer.cast(@name, {:fetch, name})
  end

  def fetch_all() do
    GenServer.cast(@name, :fetch_all)
  end

  def register(meeting_id, application) do
    meeting = get_by_meeting_id(meeting_id)

    GenServer.call(@name, {:register, {meeting, application}})
  end

  defp parse(delegate, name) do
    {to_index, grouped} =
      delegate.meetings
      |> Enum.reduce({[], []}, fn %{
                                    academy_id: academy_id,
                                    certifier_id: certifier_id,
                                    meetings: meetings
                                  },
                                  {to_index, new_state} ->
        formatted =
          meetings
          |> Enum.map(fn
            %Meeting{postal_code: nil} = meeting ->
              meeting

            %Meeting{city: nil} = meeting ->
              meeting

            %Meeting{city: city, postal_code: postal_code} = meeting ->
              geolocation =
                case Places.get_geoloc_from_city(city) do
                  nil -> Places.get_geoloc_from_postal_code(postal_code)
                  geoloc -> geoloc
                end

              %{
                meeting
                | geolocation: geolocation,
                  name: name
              }

            %Meeting{postal_code: postal_code} = meeting ->
              geolocation = Places.get_geoloc_from_postal_code(postal_code)

              %{
                meeting
                | geolocation: geolocation,
                  name: name
              }
          end)
          |> Enum.group_by(&{&1.geolocation["_geoloc"], &1.place, &1.address})
          |> Enum.map(fn {headers, meetings} ->
            format(headers, %{
              academy_id: academy_id,
              certifier_id: certifier_id,
              meetings: meetings
            })
          end)

        {
          formatted
          |> Enum.map(fn meeting ->
            Map.take(
              meeting,
              [:id, :_geoloc, :place, :address, :academy_id, :certifier_id, :has_academy]
            )
          end)
          |> Kernel.++(to_index),
          formatted ++ new_state
        }
      end)

    %{delegate | grouped_meetings: grouped, indexed_meetings: to_index}
  end

  defp index_and_persist(%Delegate{indexed_meetings: to_index} = delegate, name) do
    with {:ok, objects} <- AlgoliaClient.save_objects(:meetings, to_index),
         true <- persist(delegate, name) do
      Logger.info("Saved #{Kernel.length(objects["objectIDs"])} meetings(s) for #{name}")
      {:ok, delegate}
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        {:error, msg}

      false ->
        msg = "Error while inserting state into meetings ets table"
        Logger.error(msg)
        {:error, msg}
    end
  end

  defp format(
         {geoloc, place, address},
         %{academy_id: academy_id, certifier_id: certifier_id, meetings: meetings}
       ),
       do: %{
         id: UUID.uuid5(nil, "#{place} #{address}"),
         _geoloc: geoloc,
         address: address,
         place: place,
         academy_id: academy_id,
         certifier_id: certifier_id,
         has_academy: !!academy_id,
         meetings: Enum.map(meetings, &Map.from_struct/1)
       }

  defp from_delegates(delegates) do
    delegates
    |> Enum.flat_map(& &1.grouped_meetings)
  end

  defp from_ets(tab) do
    tab
    |> :ets.tab2list()
    |> Enum.map(fn {_name, _updated_at, delegate} -> delegate end)
  end

  defp persist(delegate, name) do
    :ets.insert(:meetings, {name, delegate.updated_at, delegate})
  end

  defp handle_meetings_result({:ok, places}, state) do
    meetings =
      places
      |> Enum.map(fn %{id: id, place: place, address: address} ->
        meetings =
          state
          |> from_delegates()
          |> Enum.find(&(&1[:id] == id))
          |> case do
            nil ->
              []

            delegate ->
              delegate
              |> Map.get(:meetings)
              |> Enum.sort_by(fn meeting -> meeting.start_date end, &Timex.before?/2)
          end

        {{place, address, Vae.String.parameterize(place)}, meetings}
      end)
      |> Enum.filter(fn {_places, meetings} -> not is_nil(meetings) and meetings != [] end)

    {:reply, meetings, state}
  end

  defp handle_meetings_result({:error, msg}, state) do
    Logger.error(msg)
    {:reply, [], state}
  end
end
