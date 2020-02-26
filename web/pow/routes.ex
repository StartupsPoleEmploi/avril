defmodule Vae.Pow.Routes do
  require Logger

  use Pow.Phoenix.Routes
  import Phoenix.Controller
  alias Vae.Router.Helpers, as: Routes

  alias Vae.{
    Application,
    Repo,
    User
  }

  # Example usage
  # Uncomment the following line to return the user to the login form after logging out
  def after_sign_out(conn, user) do
    case user do
      %User{pe_id: pe_id} when not is_nil(pe_id) ->
        url =
          "https://authentification-candidat.pole-emploi.fr/compte/deconnexion/compte/deconnexion?id_token_hint=#{
            pe_id
          }&redirect_uri=#{Routes.root_url(conn, :index)}"

        redirect(conn, external: url)

      _ ->
        redirect(conn, to: Routes.root_path(conn, :index))
    end
  end

  def after_sign_in(conn) do
    create_or_get_application(conn)
  end

  def after_registration(conn) do
    create_or_get_application(conn)
  end

  def create_or_get_application(conn) do
    user = Pow.Plug.current_user(conn)

    if is_nil(user) do
      redirect(conn, to: Routes.root_path(conn, :index))
    else
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
  end

  def redirect_to_user_application(conn, _user, nil) do
    conn
    |> put_flash(:success, "Sélectionnez un diplôme pour démarrer une candidature")
    |> redirect(to: Routes.root_path(conn, :index))
  end
  def redirect_to_user_application(conn, user, application) do
    conn
      |> Pow.Plug.refresh_current_user()
      |> welcome_message_if_necessary(user)
      |> redirect(to: Routes.application_path(conn, :show, application.id))
  end

  def welcome_message_if_necessary(conn, user) do
    todos = [
      (unless User.address(user), do: "compléter vos informations"),
      (unless user.email_confirmed_at, do: "confirmer votre adresse email")
    ] |> Enum.filter(&(&1))

    if is_nil(get_flash(conn, :success)) && length(todos) > 0 do
      message = "Bienvenue sur votre page de candidature. Merci de #{todos |> Enum.join(" et ")} avant de transmettre votre profil."
      put_flash(conn, :success, message)
    else
      conn
    end
  end

  def current_application_path(conn) do
    application = Pow.Plug.current_user(conn)
    |> Repo.preload(:applications)
    |> Map.get(:applications)
    |> List.first()

    Routes.application_path(conn, :show, application.id)
  end
end