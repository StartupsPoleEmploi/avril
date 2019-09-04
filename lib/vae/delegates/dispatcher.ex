defmodule Vae.Delegates.Dispatcher do
  require Logger
  use GenServer

  @doc false
  def start_link() do
    start_link([])
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: DelegatesDispatcher)
  end

  def init(_state) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:subscribe, name, data}, state) do
    Logger.info(fn -> inspect("#{name} subscribed") end)

    {to_index, new_state} =
      data
      |> Enum.reduce({[], []}, fn %{
                                    academy_id: academy_id,
                                    certifier_id: certifier_id,
                                    meetings: meetings
                                  },
                                  {to_index, new_state} = acc ->
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

    with {:ok, objects} <- Algolia.save_objects("test-meetings", to_index, id_attribute: :id) do
      Logger.info("Saved #{Kernel.length(objects["objectIDs"])} meetings(s) for #{name}")
      {:noreply, new_state ++ state}
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:save, name, data}, state) do
    new_state = Keyword.put(state, name, data)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:fetch_all, state) do
    Logger.info(fn -> inspect(state) end)
    {:noreply, state}
  end

  @impl true
  def handle_call(:all, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call({:get, delegate}, _from, state) do
    Vae.Search.Client.Algolia.get_meetings(delegate)
    |> IO.inspect()

    {:reply, [], state}
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

  def fetch_all() do
    GenServer.cast(DelegatesDispatcher, :fetch_all)
  end

  def fetch(server) do
    GenServer.cast(DelegatesDispatcher, {:fetch, server})
  end

  def subscribe(who, meetings) do
    GenServer.cast(DelegatesDispatcher, {:subscribe, who, meetings})
  end

  def save(name, data) do
    GenServer.cast(DelegatesDispatcher, {:save, name, data})
  end

  def all() do
    GenServer.call(DelegatesDispatcher, :all)
  end

  def get(delegate) do
    GenServer.call(DelegatesDispatcher, {:get, delegate})
  end
end
