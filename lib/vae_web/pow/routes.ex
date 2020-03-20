defmodule VaeWeb.Pow.Routes do
  require Logger

  use Pow.Phoenix.Routes
  import Phoenix.Controller
  alias VaeWeb.Router.Helpers, as: Routes

  alias Vae.{UserApplication, User}

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
    conn
    |> maybe_create_application_and_redirect()
  end

  def after_registration(conn) do
    conn
    |> maybe_create_application_and_redirect()
  end

  def maybe_create_application_and_redirect(conn, certification_id \\ nil) do
    with(
      current_user when not is_nil(current_user) <- Pow.Plug.current_user(conn),
      certification_id when not is_nil(certification_id) <-
        certification_id || Plug.Conn.get_session(conn, :certification_id),
      {:ok, _application} <-
        UserApplication.find_or_create_with_params(%{
          user_id: current_user.id,
          certification_id: certification_id
        })
    ) do
      Plug.Conn.delete_session(conn, :certification_id)
    else
      error ->
        Logger.warn("Application not created: #{inspect(error)}")
        conn
    end
    |> redirect_to_user_space()
  end

  defp redirect_to_user_space(conn) do
    if Pow.Plug.current_user(conn) do
      user_space_path = System.get_env("NUXT_PROFIL_PATH")

      if user_space_path do
        redirect(conn, to: user_space_path)
      else
        conn
        |> put_flash(
          :warning,
          "Votre profil utilisateur n'est pas accessible, merci de revenir plus tard."
        )
        |> redirect(to: Routes.root_path(conn, :index))
      end
    else
      redirect(conn, to: Routes.pow_session_path(conn, :new))
    end
  end
end
