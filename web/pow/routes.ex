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
  def after_sign_out_path(conn) do
    case Pow.Plug.current_user(conn) && Pow.Plug.current_user(conn).pe_id do
      nil ->
        redirect(conn, to: Routes.root_path(conn, :index))

      token ->
        url =
          "https://authentification-candidat.pole-emploi.fr/compte/deconnexion/compte/deconnexion?id_token_hint=#{
            token
          }&redirect_uri=#{Routes.root_url(conn, :index)}"

        redirect(conn, external: url)
    end
  end

  def after_sign_in_path(conn) do
    create_or_get_application(conn, Pow.Plug.current_user(conn))
  end

  def after_registration_path(conn) do
    create_or_get_application(conn, Pow.Plug.current_user(conn))
  end

  def after_email_confirmed_path(conn) do
    create_or_get_application(conn, Pow.Plug.current_user(conn))
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
        # |> Pow.Plug.refresh_current_user()
        |> reload_user()
        |> welcome_message_if_necessary(user)
        |> redirect(to: Routes.application_path(conn, :show, application.id))
    else
      conn
        |> redirect(to: Routes.root_path(conn, :index))
    end
  end

  def welcome_message_if_necessary(conn, user) do
    todos = [
      (unless User.address(user), do: "compléter vos informations"),
      (unless user.email_confirmed_at, do: "confirmer votre adresse email")
    ] |> Enum.filter(&(&1))
    if length(todos) > 0 do
      message = "Bienvenue sur votre page de candidature. Merci de #{todos |> Enum.join(" et ")} avant de transmettre votre profil."

      Phoenix.Controller.put_flash(conn, :success, message)
    else
      conn
    end
  end

  def reload_user(conn) do
    config = Pow.Plug.fetch_config(conn)
    user = Pow.Plug.current_user(conn, config)
    reloaded_user = Repo.get!(User, user.id)

    Pow.Plug.assign_current_user(conn, reloaded_user, config)
  end
end