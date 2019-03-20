defmodule Vae.UserController do
  require Logger
  use Vae.Web, :controller

  alias Vae.User

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    redirect_or_show(conn, user)
  end

  defp redirect_or_show(conn, nil) do
    conn
    |> put_flash(:error, "Vous n'avez pas accès.")
    |> redirect(to: root_path(conn, :index))
  end

  defp redirect_or_show(conn, user) do
    render(conn, "show.html", user: user, layout: {Vae.LayoutView, "home-white.html"})
  end

end
