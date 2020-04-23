defmodule VaeWeb.Plugs.APIErrorHandler do
  use VaeWeb, :controller
  alias Plug.Conn
  alias VaeWeb.Router.Helpers, as: Routes

  @spec call(Conn.t(), :not_authenticated) :: Conn.t()
  def call(conn, :not_authenticated) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      error: %{
        code: 401,
        message: "Not authenticated",
        redirect_to: Routes.pow_session_url(conn, :new)
      }
    })
  end
  def call(conn, :unauthorized) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      error: %{
        code: 401,
        message: "Unauthorized",
      }
    })
  end

  @spec call(Conn.t(), :not_found) :: Conn.t()
  def call(conn, :not_found) do
    conn
    |> put_status(:not_found)
    |> json(%{
      error: %{
        code: 404,
        message: "Not found"
      }
    })
  end

  @spec call(Conn.t(), :internal_server_error) :: Conn.t()
  def call(conn, :internal_server_error) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{
      error: %{
        code: 500,
        message: "Application error"
      }
    })
  end
end
