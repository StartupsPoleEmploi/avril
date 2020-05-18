defmodule VaeWeb.Plugs.ErrorHandlers.Browser do
  use VaeWeb, :controller
  alias VaeWeb.Router.Helpers, as: Routes
  alias Plug.Conn

  @spec call(Conn.t(), :not_found) :: Conn.t()
  def call(conn, :not_found) do
    conn
    |> Plug.Conn.put_status(:not_found)
    |> Phoenix.Controller.put_view(VaeWeb.ErrorView)
    |> Phoenix.Controller.render("404.html", layout: false)
  end

  @spec call(Conn.t(), :internal_server_error) :: Conn.t()
  def call(conn, :internal_server_error) do
    conn
    |> Plug.Conn.put_status(:internal_server_error)
    |> Phoenix.Controller.put_view(VaeWeb.ErrorView)
    |> Phoenix.Controller.render("500.html", layout: false)
  end

  @spec call(Conn.t(), :unauthorized) :: Conn.t()
  def call(conn, :unauthorized) do
    conn
    |> Phoenix.Controller.put_flash(:error, "Vous n'avez pas accès")
    |> Phoenix.Controller.redirect(to: Routes.root_path(conn, :index))
  end

  @spec call(Conn.t(), :not_authenticated) :: Conn.t()
  def call(conn, :not_authenticated) do
    conn
    |> put_flash(:error, "Merci de vous connecter pour accéder à cette page")
    |> redirect(to: Routes.login_path(conn, :new))
  end

  @spec call(Conn.t(), :already_authenticated) :: Conn.t()
  def call(conn, :already_authenticated) do
    conn
    |> put_flash(:error, "Vous êtes déjà connecté")
    |> redirect(to: Routes.root_path(conn, :index))
  end
end
