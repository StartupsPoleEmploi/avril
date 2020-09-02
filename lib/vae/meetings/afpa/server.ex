defmodule Vae.Meetings.Afpa.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.Afpa.Scraper
  alias Vae.Meeting

  @name :afpa

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(state) do
    Logger.info("[AFPA] Init #{@name} server")
    {:ok, state}
  end

  @impl true
  def handle_cast({:fetch, pid, delegate}, state) do
    new_state =
      Map.merge(
        state,
        %{
          req_id: delegate.req_id,
          updated_at: delegate.updated_at,
          meetings: [
            %{
              certifier_id: 4,
              academy_id: nil,
              meetings: get_data(pid, delegate.req_id)
            }
          ]
        }
      )

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:register, {meeting, _application}}, _from, state) do
    {:reply, {:ok, meeting}, state}
  end

  defp get_data(pid, req_id) do
    Scraper.scrape_all_events()
    |> Flow.from_enumerable(max_demand: 5, window: Flow.Window.count(10))
    |> Flow.map(fn id ->
      Scraper.scrape_event("https://www.afpa.fr/agenda/#{id}")
    end)
    |> Flow.filter(&(not is_nil(&1) && Map.has_key?(&1, :place)))
    |> Flow.partition(key: {:key, :place})
    |> Flow.reduce(fn -> [] end, fn
      meeting, acc when meeting == [] or is_nil(meeting) ->
        acc

      meeting, acc ->
        [
          %{
            struct(%Meeting{}, meeting)
            | meeting_id:
                UUID.uuid5(
                  nil,
                  "#{meeting[:place]} #{meeting[:start_date]}"
                ),
              end_date: Timex.add(meeting[:start_date], Timex.Duration.from_hours(3))
          }
          | acc
        ]
    end)
    |> Enum.to_list()
  end
end
