defmodule Vae.Meetings.StateHolder do
  require Logger
  use GenServer

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
      PersistentEts.new(:meetings, "meetings.tab", [:named_table, :public])
      |> from_ets()

    {:ok, state}
  end

  @impl true
  def handle_cast({:save, name, delegate}, _state) do
    new_state =
      delegate
      |> parse()
      |> index_and_persist(name)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:subscribe, name}, state) do
    Logger.info(fn -> "#{name} subscribed" end)

    case :ets.lookup(:meetings, name) do
      [] ->
        GenServer.cast(name, {:fetch, self()})

      [{_delegate_name, updated_at, _grouped_meetings}] ->
        case DateTime.compare(
               Timex.add(updated_at, Timex.Duration.from_hours(12)),
               DateTime.utc_now()
             ) do
          :lt ->
            GenServer.cast(name, {:fetch, self()})

          _ ->
            nil
        end
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:save, name, data}, state) do
    new_state = Keyword.put(state, name, data)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:fetch_all, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:all, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:get, delegate}, _from, state) do
    case Vae.Search.Client.Algolia.get_meetings(delegate) do
      {:ok, places} ->
        meetings =
          places
          |> Enum.map(fn %{id: id, place: place, address: address} ->
            found = Enum.find(state, &(&1[:id] == id))
            {{place, address, Vae.String.parameterize(place)}, found[:meetings]}
          end)

        {:reply, meetings, state}
      {:error, msg} ->
        Logger.error(msg)
        {:reply, [], state}
    end
  end

  @impl true
  def handle_call({:get_by_meeting_id, meeting_id}, _from, state) do
    meeting =
      state
      |> Enum.flat_map(& &1[:meetings])
      |> Enum.find(fn meeting -> meeting.meeting_id2 == meeting_id end)

    {:reply, meeting, state}
  end

  def fetch_all() do
    GenServer.cast(@name, :fetch_all)
  end

  def subscribe(who) do
    GenServer.cast(@name, {:subscribe, who})
  end

  def save(name, data) do
    GenServer.cast(@name, {:save, name, data})
  end

  def all() do
    GenServer.call(@name, :all)
  end

  def get(delegate) do
    GenServer.call(@name, {:get, delegate})
    |> Enum.filter(fn {_places, meetings} -> not is_nil(meetings) end)
  end

  def get_by_meeting_id(meeting_id) do
    GenServer.call(@name, {:get_by_meeting_id, meeting_id})
  end

  defp parse(delegate) do
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

    {to_index, %{delegate | grouped_meetings: grouped}}
  end

  defp index_and_persist({to_index, delegate}, name) do
    with {:ok, objects} <- Algolia.save_objects("test-meetings", to_index, id_attribute: :id),
         true <- persist(delegate, name),
         new_state <- from_ets() do
      Logger.info("Saved #{Kernel.length(objects["objectIDs"])} meetings(s) for #{name}")
      new_state
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        []

      false ->
        Logger.error("Error while inserting state into meetings ets table")
        []
    end
  end

  defp format(
         {geoloc, place, address},
         %{academy_id: academy_id, certifier_id: certifier_id, meetings: meetings}
       ),
       do: %{
         id: UUID.uuid5(nil, "#{place} #{address}"),
         _geoloc: geoloc,
         place: place,
         address: address,
         academy_id: academy_id,
         certifier_id: certifier_id,
         has_academy: !!academy_id,
         meetings: Enum.map(meetings, &Map.from_struct/1)
       }

  defp from_ets(tab \\ :meetings) do
    tab
    |> :ets.tab2list()
    |> Enum.flat_map(fn {_name, _updated_at, grouped_meetings} -> grouped_meetings end)
  end

  defp persist(delegate, name) do
    :ets.insert(:meetings, {name, delegate.updated_at, delegate.grouped_meetings})
  end
end
