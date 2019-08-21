defmodule Vae.Delegates.FranceVae.Server do
  require Logger
  use GenServer

  alias Vae.Delegates.FranceVae

  @doc false
  def start_link(delegate) do
    GenServer.start_link(__MODULE__, delegate, name: delegate)
  end

  @impl true
  def init(delegate) do
    Logger.info("Init #{delegate} server")

    state = %{
      name: delegate,
      data: []
    }

    {:ok, state, {:continue, :get_data}}
  end

  @impl true
  def handle_continue(:get_data, state) do
    data = get_data(state.name)
    updated_state = Map.put(state, :data, data)

    {:noreply, updated_state}
  end

  @impl true
  def handle_call(:get_academies, _from, state) do
    {:reply, FranceVae.get_academies(), state}
  end

  @impl true
  def handle_call({:get_meetings, academy_id}, _from, state) do
    {:reply, FranceVae.get_meetings(academy_id), state}
  end

  @impl true
  def handle_call({:register_to_meeting, academy_id, meeting_id, user}, _from, state) do
    {:reply, FranceVae.register(academy_id, meeting_id, user), state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error(fn -> inspect("Incoming unknown msg: #{msg}") end)
    {:no_reply, state}
  end

  defp get_data(:france_vae) do
    FranceVae.get_academies()
    |> Enum.reduce([], fn %{"id" => id, "nom" => name}, acc ->
      [%{id: id, name: name} | acc]
    end)
  end
end
