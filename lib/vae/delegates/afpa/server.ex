defmodule Vae.Delegates.Afpa.Server do
  require Logger
  use GenServer

  alias Vae.Delegates.Dispatcher
  alias Vae.Delegates.FranceVae.Meeting

  @name Afpa

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(name) do
    Logger.info("Init #{name} server")

    state = %{
      meetings: []
    }

    {:ok, state, {:continue, :get_data}}
  end

  @impl true
  def handle_continue(:get_data, state) do
    new_state = [
      %{
        certifier_id: 4,
        academy_id: nil,
        meetings:
          Vae.Delegates.Afpa.Scraper.scrape_all_events()
          |> Enum.map(fn meeting -> struct(%Meeting{}, meeting) end)
      }
    ]

    Dispatcher.subscribe(@name, new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_meetings, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_meetings, _from, state) do
    {:reply, state[:meetings], state}
  end
end
