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
    current_user = 
      if conn.assigns[:current_application] do
        Vae.Repo.preload(conn.assigns[:current_application], :user).user
      else
        if conn.assigns[:current_user] do
          Vae.Account.get_user(conn.assigns[:current_user].id)
        end
      end

    user_id = Plug.Conn.get_session(conn, :admin_current_user_id)
    if user_id && current_user && current_user.is_admin do
      Vae.Account.get_user(user_id)
    else 
      current_user
    end
  end
end
