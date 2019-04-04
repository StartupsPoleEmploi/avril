defmodule Vae.UserController do
  require Logger
  use Vae.Web, :controller
  plug Coherence.Authentication.Session, protected: true

  alias Vae.User

  def show(conn, %{"id" => id}) do
    user = Coherence.current_user(conn) |> Repo.preload([:delegate, :certification])
    if !is_nil(user) && Coherence.current_user(conn).id == String.to_integer(id) do
     render(conn, "show.html",
      user: user,
      changeset: User.changeset(user, %{})
    )
    else
      conn
      |> put_flash(:error, "Vous n'avez pas accès.")
      |> redirect(to: root_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Coherence.current_user(conn)

    user
    |> User.changeset(user_params)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        conn
        |> put_flash(:success, "Enregistré")
        |> Coherence.Authentication.Session.update_login(user)
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        user = Repo.preload(user, [:delegate, :certification])
        render(conn, "show.html", user: user, changeset: changeset)
    end
  end


end
