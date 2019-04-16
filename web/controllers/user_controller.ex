defmodule Vae.UserController do
  require Logger
  use Vae.Web, :controller
  plug Coherence.Authentication.Session, protected: true

  alias Vae.User

  def update(conn, %{"id" => _id, "user" => user_params}) do
    Coherence.current_user(conn)
    |> User.changeset(user_params)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        conn
        |> put_flash(:success, "Enregistré")
        |> Coherence.Authentication.Session.update_login(user)
        |> redirect(to: application_path(conn, :show, Coherence.current_user(conn).current_application))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Une erreur est survenue")
        |> redirect(to: application_path(conn, :show, Coherence.current_user(conn).current_application))
    end
  end
end
