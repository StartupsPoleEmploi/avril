defmodule VaeWeb.Plugs.AddGraphqlContext do
  @behaviour Plug
  alias Vae.{Repo, User}

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
    current_user =
      if conn.assigns[:current_application] do
        Vae.Repo.preload(conn.assigns[:current_application], :user).user
      else
        if conn.assigns[:current_user] do
          Repo.get(User, conn.assigns[:current_user].id)
        end
      end

    user_id = Plug.Conn.get_session(conn, Application.get_env(:ex_admin, :override_user_id_session_key))
    if user_id && current_user && current_user.is_admin do
      Repo.get(User, user_id)
    else
      current_user
    end
  end
end
