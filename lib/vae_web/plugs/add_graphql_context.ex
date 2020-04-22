defmodule VaeWeb.Plugs.AddGraphqlContext do
  @behaviour Plug

  alias Vae.{UserApplication, User}

  def init(opts), do: opts

  def call(conn, _) do
    Absinthe.Plug.put_options(conn, context: get_user(conn) |> (fn u -> if u, do: %{current_user: u}, else: %{} end).())
  end

  defp get_user(conn) do
    if conn.assigns[:current_application] do
      Vae.Repo.preload(conn.assigns[:current_application], :user).user
    else
      if conn.assigns[:current_user] do
        refresh_and_retrieve(conn, conn.assigns[:current_user])
      end
    end
  end

  defp refresh_and_retrieve(conn, user) do
    conn
    |> Pow.Plug.create(Vae.Account.get_user(user.id))
    |> Pow.Plug.current_user()
  end
end
