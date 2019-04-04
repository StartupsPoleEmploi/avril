defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller
  plug Coherence.Authentication.Session, protected: true

  alias Vae.User
  alias Vae.Application

  def show(conn, %{"id" => id}) do
    application = Repo.get(Application, id)
    |> Repo.preload([:user, :delegate, :certification])
    if !is_nil(application) && Coherence.current_user(conn).id == application.user.id do
     render(conn, "show.html",
      application: application,
      delegate: application.delegate,
      certification: application.certification,
      user: application.user,
      changeset: User.changeset(application.user, %{})
    )
    else
      conn
      |> put_flash(:error, "Vous n'avez pas accès.")
      |> redirect(to: root_path(conn, :index))
    end
  end
end
