defmodule Vae.Delegates.Afpa.Server do
  require Logger
  use GenServer

  @name Afpa
  @ets_table :afpa_meetings
  @ets_key :meetings

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(delegate) do
    Logger.info("Init #{delegate} server")
    PersistentEts.new(@ets_table, "#{@ets_table}.tab", [
      :set,
      :named_table,
      :protected
      # read_concurrency: true,
      # write_concurrency: true
    ])
    if length(get_meetings()) == 0 do
      do_refresh()
    end
    {:ok, nil}
  end

  @impl true
  def handle_call(:get_meetings, _from, state) do
    {:reply, get_meetings(), state}
  end

  @impl true
  def handle_info(:refresh, state) do
    do_refresh()
    {:noreply, state}
  end

  @impl true
  def handle_cast(:refresh, state) do
    do_refresh()
    {:noreply, state}
  end

  defp get_meetings() do
    case :ets.lookup(@ets_table, @ets_key) do
      [{@ets_key, meetings}] -> meetings
      [] -> []
    end
  end

  defp do_refresh() do
    :ets.insert(@ets_table, {@ets_key, Vae.Delegates.Afpa.Scraper.scrape_all_events()})
    schedule_refresh()
  end

  defp schedule_refresh() do
    next_day_5_am = Timex.now() |> Timex.end_of_day() |> Timex.shift(hours: 5)
    next_run_seconds_delay = Timex.diff(next_day_5_am, Timex.now(), :seconds)
    Process.send_after(self(), :refresh, next_run_seconds_delay)
  end
end
