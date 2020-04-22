defmodule VaeWeb.Plugs.APIAuthErrorHandler do
  use VaeWeb, :controller
  alias Plug.Conn
  alias VaeWeb.Router.Helpers, as: Routes

  @spec call(Conn.t(), :not_authenticated) :: Conn.t()
  def call(conn, :not_authenticated) do
    conn
    |> put_status(401)
    |> json(%{
      error: %{
        code: 401,
        message: "Not authenticated",
        redirect_to: Routes.pow_session_url(conn, :new)
      }
    })
  end
end
