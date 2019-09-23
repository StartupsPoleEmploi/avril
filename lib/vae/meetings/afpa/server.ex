defmodule Vae.Meetings.Afpa.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.Afpa.Scraper
  alias Vae.Meetings.StateHolder
  alias Vae.Meetings.{Delegate, Meeting}

  @name :afpa

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, Delegate.new(@name), name: @name)
  end

  @impl true
  def init(state) do
    Logger.info("[AFPA] Init #{@name} server")

    StateHolder.subscribe(@name)

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

  defp get_data(pid, req_id) do
    Scraper.scrape_all_events()
    |> Flow.from_enumerable(max_demand: 5, window: Flow.Window.count(10))
    |> Flow.map(fn id ->
      Scraper.scrape_event("https://www.afpa.fr/agenda/#{id}")
    end)
    |> Flow.reduce(fn -> [] end, fn
      meeting, acc when meeting == [] or is_nil(meeting) ->
        acc

      meeting, acc ->
        [
          %{
            struct(%Meeting{}, meeting)
            | meeting_id2:
                UUID.uuid5(
                  nil,
                  "#{meeting[:place]} #{meeting[:start_date]}"
                ),
              end_date: Timex.add(meeting[:start_date], Timex.Duration.from_hours(3))
          }
          | acc
        ]
    end)
    |> Flow.on_trigger(fn meetings ->
      global = %Delegate{
        req_id: req_id,
        name: @name,
        updated_at: DateTime.utc_now(),
        meetings: [
          %{
            certifier_id: 4,
            academy_id: nil,
            meetings: meetings
          }
        ]
      }

      GenServer.cast(pid, {:save, @name, global})

      {meetings, []}
    end)
    |> Enum.to_list()
  end
end
