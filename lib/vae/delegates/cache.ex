defmodule Vae.Delegates.Cache do
  use Agent

  alias Vae.Delegates.Connection

  def start_link(_args) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def add_token(response_body, delegate) do
    connection = map_to_connection(response_body, delegate)

    {
      Agent.update(__MODULE__, fn state ->
        Keyword.put(
          state,
          String.to_atom(delegate),
          connection
        )
      end),
      connection.access_token
    }
  end

  def get_token(delegate) do
    Agent.get(__MODULE__, fn state ->
      Keyword.get(state, String.to_atom(delegate))
    end)
    |> case do
      nil ->
        {:none, delegate}

      %Connection{init_at: init_at, access_token: access_token, expires_in: expires_in} ->
        init_at
        |> DateTime.add(expires_in, :second)
        |> DateTime.compare(DateTime.utc_now())
        |> case do
          :lt -> {:none, delegate}
          _ -> {:ok, access_token}
        end
    end
  end

  defp map_to_connection(
         %{"access_token" => access_token, "expires_in" => expires_in},
         delegate
       ) do
    %Connection{
      delegate: String.to_atom(delegate),
      access_token: access_token,
      expires_in: expires_in
    }
  end
end
