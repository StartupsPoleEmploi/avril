defmodule VaeWeb.SessionController do
  use VaeWeb, :controller

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.authenticate_user(user_params)
    |> case do
      {:ok, conn} ->
        conn
        |> maybe_make_session_persistent(user_params)
        |> VaeWeb.RegistrationController.maybe_create_application_and_redirect()
        |> redirect(external: VaeWeb.RegistrationController.get_after_signup_path(conn))

      {:error, conn} ->
        changeset = Pow.Plug.change_user(conn, conn.params["user"])

        conn
        |> put_flash(:danger, "L'authentification a échoué. Merci de réessayer ou de cliquer sur \"Mot de passe oublié ?\" si vous ne parvenez pas à le retrouver.")
        |> render("new.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do

    redirect_to = case Pow.Plug.current_user(conn) do
      %Vae.User{pe_id: pe_id} when not is_nil(pe_id) ->
        {:external, "https://authentification-candidat.pole-emploi.fr/compte/deconnexion/compte/deconnexion?id_token_hint=#{pe_id}&redirect_uri=#{Routes.root_url(conn, :index)}" }
      _ ->
        {:to, Routes.root_path(conn, :index)}
    end

    conn
    |> Plug.Conn.delete_session(Application.get_env(:ex_admin, :override_user_id_session_key))
    |> Pow.Plug.delete()
    |> PowPersistentSession.Plug.delete()
    |> put_flash(:info, "Vous êtes maintenant déconnecté")
    |> redirect([redirect_to])
  end

  def maybe_make_session_persistent(conn, %{"persistent_session" => "true"}) do
    PowPersistentSession.Plug.create(conn, Pow.Plug.current_user(conn))
  end

  def maybe_make_session_persistent(conn, _user_params) do
    PowPersistentSession.Plug.delete(conn)
  end
end

