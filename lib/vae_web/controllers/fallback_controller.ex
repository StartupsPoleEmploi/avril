defmodule VaeWeb.FallbackController do
  use Phoenix.Controller

  alias Plug.Conn

  @spec call(Conn.t(), {:error, :not_found}) :: Conn.t()
  def call(conn, {:error, :not_found}) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.put_view(VaeWeb.ErrorView)
    |> Phoenix.Controller.render("404.html", layout: false)
  end
end
