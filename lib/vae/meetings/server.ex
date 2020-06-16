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
  end

  @impl true
  def handle_call({:search, delegate}, _from, state) do
    meetings =
      with {:ok, meetings} <-
             AlgoliaClient.get_france_vae_meetings(delegate.academy_id, delegate.geolocation) do
        Enum.reduce(meetings, Keyword.new(), fn meeting, acc ->
          case Keyword.get(acc, :"#{meeting.place}") do
            nil ->
              IO.inspect(meeting.place)

              Keyword.put(acc, :"#{meeting.place}", %{
                name: "#{meeting.place}",
                meetings: [Map.take(meeting, @common_fields)]
              })

            %{name: _name, meetings: meetings} ->
              meeting_to_add = Map.take(meeting, @common_fields)

              update_in(acc, [:"#{meeting.place}", :meetings], fn _ ->
                [meeting_to_add | meetings]
              end)
          end
        end)
        |> Enum.reverse()
      else
        error ->
          Logger.error(fn ->
            "Error while attempting to retrieve meetings for delegate_id #{inspect(delegate.id)}"
          end)

          []
      end

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
    Map.merge(meeting, %{
      _geoloc: geoloc["_geoloc"]
    })
    |> Map.take(@field_to_index)
  end
end
