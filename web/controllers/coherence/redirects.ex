defmodule Coherence.Redirects do
  require Logger
  @moduledoc """
  Define controller action redirection functions.

  This module contains default redirect functions for each of the controller
  actions that perform redirects. By using this Module you get the following
  functions:

  * session_create/2
  * session_delete/2
  * password_create/2
  * password_update/2,
  * unlock_create_not_locked/2
  * unlock_create_invalid/2
  * unlock_create/2
  * unlock_edit_not_locked/2
  * unlock_edit/2
  * unlock_edit_invalid/2
  * registration_create/2
  * invitation_create/2
  * confirmation_create/2
  * confirmation_edit_invalid/2
  * confirmation_edit_expired/2
  * confirmation_edit/2
  * confirmation_edit_error/2

  You can override any of the functions to customize the redirect path. Each
  function is passed the `conn` and `params` arguments from the controller.

  ## Examples

      import Vae.Router.Helpers

      # override the log out action back to the log in page
      def session_delete(conn, _), do: redirect(conn, to: Routes.session_path(conn, :new))

      # redirect the user to the login page after registering
      def registration_create(conn, _), do: redirect(conn, to: Routes.session_path(conn, :new))

      # disable the user_return_to feature on login
      def session_create(conn, _), do: redirect(conn, to: Routes.landing_path(conn, :index))

  """
  use Redirects
  # Uncomment the import below if adding overrides
  import Vae.Router.Helpers

  alias Vae.{Application, Repo}

  # Add function overrides below

  def confirmation_edit(conn, _) do
    current_user = Vae.Repo.get(Vae.User, Coherence.current_user(conn).id)
      |> Repo.preload(:applications)

    application = current_user
      |> Map.get(:applications)
      |> List.first()

    Coherence.Authentication.Session.update_login(conn, current_user)
    Plug.Conn.assign(conn, :current_user, current_user)

    redirect_to_user_application(conn, current_user, application)
  end

  # Example usage
  # Uncomment the following line to return the user to the login form after logging out
  def session_delete(conn, _) do
    case Coherence.current_user(conn).pe_id do
      nil ->
        redirect(conn, to: root_path(conn, :index))

      token ->
        url =
          "https://authentification-candidat.pole-emploi.fr/compte/deconnexion/compte/deconnexion?id_token_hint=#{
            token
          }&redirect_uri=#{root_url(conn, :index)}"

        redirect(conn, external: url)
    end
  end

  def session_create(conn, _params) do
    create_or_get_application(conn, Coherence.current_user(conn))
  end

  def create_or_get_application(conn, user) do
    certification_id = Plug.Conn.get_session(conn, :certification_id)
    delegate_id = Plug.Conn.get_session(conn, :delegate_id)

    application =
      if certification_id && delegate_id do
        case Application.find_or_create_with_params(%{
          user_id: user.id,
          certification_id: certification_id,
          delegate_id: delegate_id
        }) do
          {:ok, application} ->
            Plug.Conn.delete_session(conn, :certification_id)
            Plug.Conn.delete_session(conn, :delegate_id)
            application
          error ->
            Logger.warn("Error: #{inspect(error)}")
            nil
        end
      else
        user
          |> Repo.preload(:applications)
          |> Map.get(:applications)
          |> List.first()
      end
      redirect_to_user_application(conn, user, application)
  end

  def redirect_to_user_application(conn, user, application) do
    if application do
      conn
        |> Phoenix.Controller.put_flash(
            :success,
            "Bienvenue sur votre page de candidature. Merci de compléter vos informations #{unless user.confirmed_at, do: "et confirmer votre adresse email "}avant de transmettre votre dossier au certificateur."
          )
        |> redirect(to: application_path(conn, :show, application.id))
    else
      conn
        |> Phoenix.Controller.put_flash(
          :info,
          "Vous êtes maintenant connecté !"
        )
        |> redirect(to: root_path(conn, :index))
    end
  end

end
