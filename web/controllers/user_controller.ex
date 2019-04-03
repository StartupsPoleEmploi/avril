defmodule Vae.UserController do
  require Logger
  use Vae.Web, :controller
  plug Coherence.Authentication.Session, protected: true

  alias Vae.User

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id) |> Repo.preload([:delegate, :certification])
    if !is_nil(user) && Coherence.current_user(conn).id == user.id do
     render(conn, "show.html",
      user: user,
    )
    else
      conn
      |> put_flash(:error, "Vous n'avez pas accès.")
      |> redirect(to: root_path(conn, :index))
    end
  end
end
