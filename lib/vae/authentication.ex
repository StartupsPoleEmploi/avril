defimpl ExAdmin.Authentication, for: Plug.Conn do
  alias Vae.Router.Helpers

  def use_authentication?(_), do: true
  def current_user(conn), do: Coherence.current_user(conn)
  def current_user_name(conn), do: Coherence.current_user(conn).name
  def session_path(conn, action), do: Helpers.session_path(conn, action)
end