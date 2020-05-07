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
        VaeWeb.RegistrationController.maybe_create_application_and_redirect(conn)

      {:error, conn} ->
        changeset = Pow.Plug.change_user(conn, conn.params["user"])

        conn
        |> put_flash(:error, "L'authentification a échoué. Merci de réessayer ou de cliquer sur \"Mot de passe oublié?\" si vous ne parvenez pas à le retrouver.")
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
    |> Pow.Plug.delete()
    |> put_flash(:success, "Vous êtes maintenant déconnecté")
    |> redirect([redirect_to])
  end
end

