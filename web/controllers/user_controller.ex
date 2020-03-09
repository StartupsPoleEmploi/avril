defmodule Vae.UserController do
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.User

  def update(conn, %{"id" => _id, "user" => user_params}) do
    current_user = Pow.Plug.current_user(conn) |> Vae.Repo.preload(:applications)
    current_application = List.first(current_user.applications)
    default_route = Routes.application_path(conn, :show, current_application)

    current_user
    |> User.changeset(user_params)
    |> Repo.update()
    |> case do
      {:ok, _user} ->
        conn
        |> put_flash(:success, "Vos données de profil ont bien été enregistrées")
        |> Pow.Plug.refresh_current_user()
        |> redirect_back(default: default_route)
      {:error, _changeset} ->
        conn
        |> put_flash(:danger, "Une erreur est survenue")
        |> redirect_back(default: default_route)
    end
  end
end
