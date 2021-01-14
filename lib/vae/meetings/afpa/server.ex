defmodule Vae.Meetings.Afpa.Server do
  require Logger
  use GenServer

  alias Vae.{Meetings.Afpa.Scraper, Meeting, Repo}

  @source :afpa

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @source)
  end

  @impl true
  def init(state) do
    Logger.info("[AFPA] Init #{@source} server")
    {:ok, state}
  end

  @impl true
  def handle_call(:fetch, _from, state) do
    {:ok, new_meetings} = get_data()
    {:reply, new_meetings, state}
  end

  @impl true
  def handle_call({:register, {meeting, _application}}, _from, state) do
    # Nothing is done on the afpa side
    {:reply, {:ok, meeting}, state}
  end

  defp get_data() do
    Scraper.scrape_all_events()
    |> Flow.from_enumerable(max_demand: 5, window: Flow.Window.count(10))
    |> Flow.map(fn id ->
      Scraper.scrape_event("https://www.afpa.fr/agenda/#{id}")
    end)
    |> Flow.filter(&(not is_nil(&1) && Map.has_key?(&1, :place)))
    |> Enum.to_list()
    |> Enum.reduce({:ok, []}, fn meeting_params, {:ok, results} ->
      meeting_id = UUID.uuid5(nil, "#{meeting_params[:place]} #{meeting_params[:start_date]}")

      (Meeting.get_by_meeting_id(@source, meeting_id) || %Meeting{source: "#{@source}"})
      |> Meeting.changeset(%{data: Map.merge(meeting_params, %{meeting_id: meeting_id})})
      |> Repo.insert_or_update()
      |> case do
        {:ok, new_meeting} -> {:ok, [new_meeting | results]}
        {:error, changeset} ->
          Logger.warn("Meeting could not be created:")
          Logger.warn(inspect(changeset))
          Logger.warn("Continuing anyway ...")
          {:ok, results}
      end
    end)
  end
end
