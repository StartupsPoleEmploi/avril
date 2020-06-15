defmodule Vae.Meetings.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.{Academy, Meeting}
  alias Vae.Search.Client.Algolia, as: AlgoliaClient
  alias Vae.Places

  @name MeetingsServer

  @doc false
  def start_link() do
    start_link([])
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:fetch, academy_id}, _from, state) do
    academy_meetings = GenServer.call(:france_vae, {:fetch, academy_id})

    {:reply, academy_meetings, academy_meetings ++ state}
  end

  @impl true
  def handle_call({:index, meetings}, _from, state) do
    with {:ok, objects} <- AlgoliaClient.save_objects(:fvae_meetings, meetings) do
      Logger.info("Indexed #{Kernel.length(objects.objectIDs)}")
      {:reply, meetings, state}
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        {:reply, meetings, state}
    end

    {:reply, state, state}
  end

  @impl true
  def handle_call({:search, delegate}, _from, state) do
    meetings =
      with {:ok, meetings} <-
             AlgoliaClient.get_france_vae_meetings(delegate.academy_id, delegate.geolocation) do
        Enum.map(meetings, fn meeting ->
          Map.take(meeting, [
            :academy_id,
            :address,
            :city,
            :end_date,
            :meeting_id,
            :objectID,
            :place,
            :postal_code,
            :remaining_places,
            :start_date,
            :target
          ])
        end)
      end
      |> Enum.group_by(& &1.place)
      |> Enum.reverse()

    {:reply, meetings, state}
  end

  @impl true
  def handle_call({:register, {%{name: name} = meeting, application}}, _from, state) do
    with {:ok, _registered_meeting} <-
           GenServer.call(name, {:register, {meeting, application}}, 15_000) do
      {:reply, {:ok, meeting}, state}
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        {:reply, {:error, meeting}, state}
    end
  end

  def fetch(:fvae = name, academy_id) do
    GenServer.call(@name, {:fetch, academy_id})
  end

  def register(meeting, application) do
    GenServer.call(@name, {:register, {meeting, application}})
  end

  def index(meetings) do
    formatted_meetings =
      meetings
      |> Enum.map(&format_for_index/1)

    GenServer.call(@name, {:index, formatted_meetings})
  end

  def get_by_delegate(delegate) do
    GenServer.call(@name, {:search, delegate})
  end

  defp format_for_index(%{place: place, address: address, geolocation: geoloc} = meeting) do
    #   %{
    #    _geoloc: %{"lat" => 48.8504, "lng" => 2.65077},
    #    academy_id: 24,
    #    address: "1 promenade du Belvédère",
    #    city: "Torcy",
    #    end_date: #DateTime<2020-09-29 12:30:00+02:00 CEST Europe/Paris>,
    #    id: "861d03e8-01cf-5eba-ad1b-c78cff6064d3",
    #    meeting_id: "209251",
    #    name: nil,
    #    place: "Dava Torcy, Torcy",
    #    postal_code: "77200",
    #    remaining_places: 43,
    #    start_date: #DateTime<2020-09-29 09:30:00+02:00 CEST Europe/Paris>,
    #    target: "CAP au BTS"
    #  }

    Map.merge(meeting, %{
      _geoloc: geoloc["_geoloc"]
    })
    |> Map.take([
      :_geoloc,
      :academy_id,
      :address,
      :city,
      :end_date,
      :id,
      :meeting_id,
      :place,
      :postal_code,
      :remaining_places,
      :start_date,
      :target
    ])
  end
end
