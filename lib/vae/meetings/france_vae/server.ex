defmodule Vae.Meetings.FranceVae.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.FranceVae

  @name :france_vae

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(_init_state) do
    Logger.info("[DAVA] Init #{@name} server")
    {:ok, FranceVae.get_academies() |> IO.inspect()}
  end

  @impl true
  def handle_call(:get_academies, _from, academies) do
    {:reply, academies, academies}
  end

  @impl true
  def handle_call(:fetch, _from, academies) do
    {:reply, FranceVae.fetch_all_meetings(academies), academies}
  end

  @impl true
  def handle_call({:register, meeting, application}, _from, state) do
    {:reply, FranceVae.register(meeting, application), state}
  end
end
