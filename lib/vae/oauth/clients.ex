defmodule Vae.OAuth.Clients do
  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def get_client(client_state) do
    Agent.get(__MODULE__, fn state ->
      Keyword.get(state, String.to_atom(client_state))
    end)
    |> case do
      nil -> :unknown_client
      %{client: client} -> client
    end
  end

  def add_client(client, client_state, client_nonce) do
    {
      Agent.update(__MODULE__, fn state ->
        Keyword.put(state, String.to_atom(client_state), %{
          client: client,
          state: client_state,
          nonce: client_nonce
        })
      end),
      client
    }
  end
end
