defmodule Vae.UserController do
  require Logger
  use Vae.Web, :controller
  plug Coherence.Authentication.Session, protected: true

  alias Vae.User

  def update(conn, %{"id" => _id, "user" => user_params}) do
    current_user = Coherence.current_user(conn) |> Vae.Repo.preload(:applications)
    current_application = List.first(Coherence.current_user(conn).applications)
    default_route = Routes.application_path(conn, :show, current_application)

    current_user
    |> User.changeset(user_params)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        conn
        |> put_flash(:success, "Enregistré")
        |> Coherence.Authentication.Session.update_login(user)
        |> redirect_back(
          default: default_route
        )
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Une erreur est survenue")
        |> redirect_back(
          default: default_route
        )
    end
  end
end
