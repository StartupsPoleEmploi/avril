defmodule VaeWeb.Plugs.ApiProtected do
  # import Plug.Conn

  @authenticate_current_user Pow.Plug.RequireAuthenticated
  @api_error_handler VaeWeb.Plugs.APIErrorHandler

  def init(opts), do: opts

  def call(conn, [allow_server_side: server_side_allowed]) do
    IO.inspect("~~~~~~~~~~~~~~~")
    IO.inspect("yeah")
    IO.inspect(server_side_allowed)
    IO.inspect(Plug.Conn.get_req_header(conn, "x-auth"))
    IO.inspect(System.get_env("SECRET_KEY_BASE"))
    IO.inspect("~~~~~~~~~~~~~~~")

    case {server_side_allowed, Plug.Conn.get_req_header(conn, "x-auth"), System.get_env("SECRET_KEY_BASE")} do
      {true, [header_value | _], secret_value} when header_value == secret_value ->
        IO.inspect("~~~~~~~~~~~~~~~")
        IO.inspect("passed and assigned")
        IO.inspect("~~~~~~~~~~~~~~~")
        Plug.Conn.assign(conn, :server_side_authenticated, true)
      _otherwise ->
        @authenticate_current_user.call(
          conn,
          @authenticate_current_user.init([error_handler: @api_error_handler])
        )
    end
  end

end