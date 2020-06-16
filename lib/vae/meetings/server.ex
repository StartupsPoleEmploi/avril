defmodule Vae.Meetings.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.{Academy, Meeting}
  alias Vae.Search.Client.Algolia, as: AlgoliaClient
  alias Vae.Places

  @name MeetingsServer

  @common_fields ~w(academy_id address city end_date meeting_id place postal_code remaining_places start_date target)a
  @fields_to_index ~w(_geoloc)a ++ @common_fields

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
    academy_meetings = GenServer.call(:france_vae, {:fetch, academy_id}, 15_000)
    {:reply, academy_meetings, academy_meetings ++ state}
  end

  @impl true
  def handle_call({:index, meetings}, _from, state) do
    with {:ok, %{"taskID" => task_id, "indexName" => index}} <-
           AlgoliaClient.save_objects(:fvae_meetings, meetings) do
      {:reply, {:ok, %{task_id: task_id, index: index}}, state}
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        {:reply, {:error}, state}
    end
  end

  @impl true
  def handle_call({:search, delegate}, _from, state) do
    meeting_places =
      case AlgoliaClient.get_france_vae_meetings(delegate.academy_id, delegate.geolocation) do
        {:ok, meetings} ->
          to_meeting_places(meetings)

        error ->
          Logger.error(fn ->
            "Error while attempting to retrieve meetings for delegate_id #{inspect(delegate.id)}"
          end)

          []
      end

    {:reply, meeting_places, state}
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
    GenServer.call(@name, {:search, delegate}, 15_000)
  end

  defp format_for_index(%{place: place, address: address, geolocation: geoloc} = meeting) do
    Map.merge(meeting, %{
      _geoloc: geoloc["_geoloc"]
    })
    |> Map.take(@fields_to_index)
  end

  defp to_meeting_places(meetings) do
    Enum.reduce(meetings, Keyword.new(), fn meeting, meeting_places ->
      case Keyword.get(meeting_places, :"#{meeting.place}") do
        nil ->
          new_meeting_place(meeting, meeting_places)

        %{name: _name, meetings: meetings} ->
          add_meeting_to_meeting_place(meeting, meetings, meeting_places)
      end
    end)
    |> Enum.reverse()
  end

  defp new_meeting_place(meeting, meeting_places) do
    Keyword.put(meeting_places, :"#{meeting.place}", %{
      name: "#{meeting.place}",
      meetings: [Map.take(meeting, @common_fields)]
    })
  end

  defp add_meeting_to_meeting_place(meeting, meetings, meeting_places) do
    meeting_to_add = Map.take(meeting, @common_fields)

    {_old, place_meetings} =
      get_and_update_in(
        meeting_places,
        [:"#{meeting.place}", :meetings],
        &{&1, [meeting | &1]}
      )

    place_meetings
  end
end
