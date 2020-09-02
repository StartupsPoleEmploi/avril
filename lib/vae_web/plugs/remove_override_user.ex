defmodule VaeWeb.Plugs.RemoveOverrideUser do

  def init(opts), do: opts

  def call(conn, _opts) do
    Plug.Conn.delete_session(conn, Application.get_env(:ex_admin, :override_user_id_session_key))
  end
end