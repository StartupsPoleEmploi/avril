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
      data: %{}
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
    IO.inspect(from, label: "FROM from handle_call")
    {:reply, FranceVae.get_academies(), state}
  end

  # Todo: Move to API #
  def get_france_vae_academies() do
    FranceVae.get_academies()
  end

  defp get_data(:france_vae) do
    FranceVae.get_academies()
    |> Enum.reduce(%{}, fn %{"id" => id, "nom" => name}, acc ->
      meetings = FranceVae.get_meeting_informations(id)
      Map.put(acc, id, meetings["reunions"])
    end)
  end
end
