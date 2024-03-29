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
        # |> redirect(external: VaeWeb.RegistrationController.get_after_signup_path(conn))

      {:error, conn} ->
        changeset = Pow.Plug.change_user(conn, conn.params["user"])

        conn
        |> put_flash(:danger, "L'authentification a échoué. Merci de réessayer ou de cliquer sur \"[Mot de passe oublié ?](/reset-password/new)\" si vous ne parvenez pas à le retrouver.\n\nNB : les règles de sécurité ont évolué sur Avril, il se peut que votre mot de passe ait été réinitialisé automatiquement et c'est pourquoi vous devez en créer un nouveau. Merci de votre compréhension")
        |> render("new.html", changeset: changeset)
    end
  end

  def delete(conn, params) do
    # redirect_to = case Pow.Plug.current_user(conn) do
    #   %Vae.User{pe_id: pe_id} when not is_nil(pe_id) ->
    #     {:external, "https://authentification-candidat.pole-emploi.fr/compte/deconnexion?#{URI.encode_query(%{id_token_hint: pe_id, redirect_uri: Routes.auth_url(conn, :callback, "pole-emploi")})}" }
    #   _ ->
    #     {:to, Routes.root_path(conn, :index)}
    # end

    conn
    |> Plug.Conn.delete_session(:certification_id)
    |> Plug.Conn.delete_session(Application.get_env(:ex_admin, :override_user_id_session_key))
    |> Pow.Plug.delete()
    |> PowPersistentSession.Plug.delete()
    |> put_flash(:info, (if params["delete_account"], do: "Votre compte a bien été supprimé", else: "Vous êtes maintenant déconnecté"))
    |> redirect(to: Routes.root_path(conn, :index))
  end

  def maybe_make_session_persistent(conn, %{"persistent_session" => "true"}) do
    PowPersistentSession.Plug.create(conn, Pow.Plug.current_user(conn))
  end

  def maybe_make_session_persistent(conn, _user_params) do
    PowPersistentSession.Plug.delete(conn)
  end
end

