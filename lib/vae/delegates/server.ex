defmodule Vae.Delegates do
  require Logger

  alias Vae.Delegates.Client.FranceVae

  @name Delegates

  def start_link(delegate) do
    GenServer.start_link(__MODULE__, delegate, name: delegate)
  end

  def init(delegate) do
    Logger.info("Init #{delegate} server")

    state = %{
      name: delegate,
      data: %{}
    }

    {:ok, state, {:handle_continue, :get_data}}
  end

  def handle_continue(:get_data, state) do
    data = get_data(state.name)
    updated_state = Map.put(state, :data, data)
    {:no_reply, updated_state}
  end

  defp get_data(:france_vae) do
    FranceVae.get_academies()
    |> Enum.map(fn academy ->
      FranceVae.get_meeting(academy)
    end)
  end
end
