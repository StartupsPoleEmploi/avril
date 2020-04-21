defmodule VaeWeb.Plugs.ApiProtected do
  import Phoenix.Controller
  import Plug.Conn
  alias VaeWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, [allow_server_side: server_side_allowed]) do
    current_user = Pow.Plug.current_user(conn)

    if server_side_allowed && get_req_header(conn, "x-auth") == System.get_env("SECRET_KEY_BASE") do
      conn
    else
      Pow.Plug.RequireAuthenticated.call(conn, Pow.Plug.RequireAuthenticated.init([error_handler: VaeWeb.APIAuthErrorHandler]))
    end
  end

end