defmodule VaeWeb.Plugs.AddGraphqlContext do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    current_user = get_user(conn)

    if current_user do
      Absinthe.Plug.put_options(conn, context: %{current_user: current_user})
    else
      VaeWeb.Plugs.ErrorHandlers.API.call(conn, :not_authenticated)
    end
  end

  defp get_user(conn) do
    if conn.assigns[:current_application] do
      Vae.Repo.preload(conn.assigns[:current_application], :user).user
    else
      if conn.assigns[:current_user] do
        Vae.Account.get_user(conn.assigns[:current_user].id)
        # refresh_and_retrieve(conn, conn.assigns[:current_user])
      end
    end
  end

  defp refresh_and_retrieve(conn, user) do
    conn
    |> Pow.Plug.create(Vae.Account.get_user(user.id))
    |> Pow.Plug.current_user()
  end
end
