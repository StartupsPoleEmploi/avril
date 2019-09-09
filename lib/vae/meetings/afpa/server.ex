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
    Logger.info("Init #{@name} server")

    StateHolder.subscribe(@name)

    {:ok, state}
  end

  @impl true
  def handle_continue(:get_data, state) do
    new_state = %{
      state
      | updated_at: DateTime.utc_now(),
        meetings: get_data()
    }

    {:noreply, new_state}
  end

  def handle_call(:fetch, _from, state) do
    new_state = %{
      state
      | updated_at: DateTime.utc_now(),
        meetings: get_data()
    }

    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:get_meetings, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_meetings, _from, state) do
    {:reply, state[:meetings], state}
  end

  defp get_data() do
    [
      %{
        certifier_id: 4,
        academy_id: nil,
        meetings:
          Scraper.scrape_all_events()
          |> Enum.filter(&(&1 != []))
          |> Enum.map(fn meeting ->
            %{
              struct(%Meeting{}, meeting)
              | meeting_id2:
                  UUID.uuid5(
                    nil,
                    "#{meeting[:place]} #{meeting[:start_date]}"
                  ),
                end_date: Timex.add(meeting[:start_date], Timex.Duration.from_hours(3))
            }
          end)
      }
    ]
  end
end
