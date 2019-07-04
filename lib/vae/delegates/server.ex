defmodule Vae.Delegates do
  require Logger
  use GenServer

  alias Vae.Delegates.Client.FranceVae

  @name Delegates

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

  def handle_call(:get_academies, from, state) do
    {:reply, FranceVae.get_academies(), state}
  end

  def handle_call({:get_meetings, academy_id}, from, state) do
    {:reply, FranceVae.get_meetings(academy_id), state}
  end

  defp get_data(:france_vae) do
    FranceVae.get_academies()
    |> Enum.reduce([], fn %{"id" => id, "nom" => name}, acc ->
      [%{id: id, name: name} | acc]
    end)
  end
end
