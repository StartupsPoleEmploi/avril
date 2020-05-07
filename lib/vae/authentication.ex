defimpl ExAdmin.Authentication, for: Plug.Conn do
  alias VaeWeb.Router.Helpers, as: Routes

  def use_authentication?(_), do: true
  def current_user(conn), do: Pow.Plug.current_user(conn)
  def current_user_name(conn), do: Pow.Plug.current_user(conn).name
  def session_path(conn, :delete), do: Routes.logout_path(conn, :delete)
  def session_path(conn, action), do: Routes.login_path(conn, action)
end