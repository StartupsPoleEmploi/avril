defmodule Vae.AuthController do
  use Vae.Web, :controller
  require Logger
  alias Vae.{OAuth, User, Application}
  alias Vae.OAuth.Clients

  def save_session_and_redirect(conn, _params) do
    referer = hd(get_req_header(conn, "referer"))

    client = OAuth.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = OAuth.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state} = params) do
    client = Clients.get_client(state)

    case OAuth.generate_access_token(client, code) do
      {:ok, client_with_token} ->
        userinfo_api_result =
          OAuth.get(
            client_with_token,
            "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo"
          )

        {:ok, user} =
          case Repo.get_by(User, pe_id: userinfo_api_result.body["idIdentiteExterne"]) do
            nil ->
              User.create_or_update_with_pe_connect_data(userinfo_api_result.body)

            user ->
              if is_nil(user.gender),
                do: User.update_with_pe_connect_data(user, userinfo_api_result.body),
                else: {:ok, user}
          end
          |> User.fill_with_api_fields(client_with_token)

      Coherence.Authentication.Session.create_login(conn, user)
      |> Coherence.Redirects.session_create(params, user)

      {:error, _error} ->
        handle_error(conn)
    end
  end

  def callback(conn, _params) do
    redirect(conn, external: get_session(conn, :referer))
  end

  defp get_certification_id_and_delegate_id_from_referer(referer) do
    string_key_map =
      Regex.named_captures(
        ~r/\/diplomes\/(?<certification_id>\d+)[0-9a-z\-]*\?certificateur=(?<delegate_id>\d+)[0-9a-z\-]*/,
        referer
      ) || %{}

    for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), val}
  end

  defp handle_error(conn, msg \\ "Une erreur est survenue. Veuillez réessayer plus tard.") do
    conn
    |> put_flash(:error, if(is_binary(msg), do: msg, else: inspect(msg)))
    |> redirect(external: get_session(conn, :referer))
  end
end
