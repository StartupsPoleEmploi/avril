defmodule VaeWeb.Context do
  @behaviour Plug

  alias Vae.User

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    case conn.assigns[:current_user] do
      %User{} = user ->
        %{current_user: refresh_and_retrieve(conn, user)}

      _ ->
        %{}
    end
  end

  defp refresh_and_retrieve(conn, user) do
    conn
    |> Pow.Plug.create(Vae.Account.get_user(user.id))
    |> Pow.Plug.current_user()
  end
end
