defmodule VaeWeb.Plugs.BrowserErrorHandler do
  alias VaeWeb.Router.Helpers, as: Routes

  def call(conn, :not_found) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.put_view(VaeWeb.ErrorView)
    |> Phoenix.Controller.render("404.html", layout: false)
  end

  def call(conn, :internal_server_error) do
    conn
    |> Plug.Conn.put_status(:internal_server_error)
    |> Phoenix.Controller.put_view(VaeWeb.ErrorView)
    |> Phoenix.Controller.render("500.html", layout: false)
  end

  def call(conn, :unauthorized) do
    conn
    |> Phoenix.Controller.put_flash(:error, "Vous n'avez pas accès")
    |> Phoenix.Controller.redirect(to: Routes.root_path(conn, :index))
  end

  def call(conn, :not_authenticated) do
    Pow.Phoenix.PlugErrorHandler.call(conn, :not_authenticated)
  end
end