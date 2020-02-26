defmodule Vae.AuthController do
  use Vae.Web, :controller
  require Logger
  alias Vae.{OAuth, User}
  alias Vae.OAuth.Clients

  def save_session_and_redirect(conn, _params) do
    referer = List.first(get_req_header(conn, "referer"))

    client = OAuth.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = OAuth.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    client = Clients.get_client(state)

    with(
      {:ok, client_with_token} <- OAuth.generate_access_token(client, code),
      %OAuth2.Response{body: userinfo_api_result_body} <- OAuth.get(
        client_with_token,
        "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo"
      )
    ) do
      result =
        case Repo.get_by(User, pe_id: userinfo_api_result_body["idIdentiteExterne"]) do
          nil ->
            User.create_or_update_with_pe_connect_data(userinfo_api_result_body)

          user ->
            if is_nil(user.gender),
              do: User.update_with_pe_connect_data(user, userinfo_api_result_body),
              else: {:ok, user}
        end
        |> User.fill_with_api_fields(client_with_token)

      case result do
        {:ok, user} ->
          Pow.Plug.create(conn, user)
          # Coherence.Authentication.Session.create_login(conn, user)
          |> Vae.Pow.Routes.create_or_get_application()
        {:error, msg} -> handle_error(conn, msg)
      end

    else
      error ->
        Logger.error(inspect(error))
        handle_error(conn)
    end
  end

  def callback(conn, _params) do
    redirect(conn, external: get_session(conn, :referer))
  end

  defp handle_error(conn, msg \\ "Une erreur est survenue. Veuillez réessayer plus tard.") do
    conn
    |> put_flash(:error, if(is_binary(msg), do: msg, else: inspect(msg)))
    |> redirect(external: get_session(conn, :referer))
  end
end
