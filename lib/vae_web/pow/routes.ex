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
      {:ok, application} <-
        UserApplication.find_or_create_with_params(%{
          user_id: current_user.id,
          certification_id: certification_id
        })
    ) do
      Plug.Conn.delete_session(conn, :certification_id)
      |> redirect_to_user_space(application)
    else
      error ->
        Logger.warn("Application not created: #{inspect(error)}")
        redirect_to_user_space(conn)
    end
  end

  defp redirect_to_user_space(conn, application \\ nil) do
    if Pow.Plug.current_user(conn) do
      redirect(conn, external: User.profile_url(conn, application))
    else
      redirect(conn, to: Routes.pow_registration_path(conn, :new))
    end
  end
end
