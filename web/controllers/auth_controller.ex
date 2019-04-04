require IEx;
defmodule Vae.AuthController do
  use Vae.Web, :controller

  alias Vae.Authentication
  alias Vae.Authentication.Clients
  alias Vae.User
  alias Vae.Application

  def save_session_and_redirect(conn, _params) do
    referer = hd(get_req_header(conn, "referer"))

    client = Authentication.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = Authentication.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state} = _params) do
    client = Clients.get_client(state)
    client_with_token = Authentication.generate_access_token(client, code)

    userinfo_api_result = Authentication.get(
      client_with_token,
      "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo"
    )

    user = (
      Repo.get_by(User, pe_id: userinfo_api_result.body["idIdentiteExterne"]) ||
      User.create_or_associate_with_pe_connect_data(client_with_token, userinfo_api_result)
      ) |> Repo.preload(:current_application)

    application =
      user.current_application ||
      Application.create_with_params(
        get_certification_id_and_delegate_id_from_referer(get_session(conn, :referer))
      )

    case user do
      nil ->
        conn
        |> put_flash(:error, "Une erreur est survenue. Veuillez réessayer plus tard.")
        |> redirect(external: get_session(conn, :referer))
      user ->
        conn = Coherence.Authentication.Session.create_login(conn, user)
        case application do
          nil ->
            conn
            |> put_flash(:info, "Sélectionnez un diplôme pour poursuivre.")
            |> redirect(to: root_path(conn, :index))
          application ->
            conn
            |> put_flash(:success, "Bienvenue sur votre page de candidat. Vous pouvez consulter vos informations avant de les soumettre au certificateur.")
            |> redirect(to: application_path(conn, :show, application))
        end
    end
  end

  defp get_certification_id_and_delegate_id_from_referer(referer) do
    string_key_map = Regex.named_captures(~r/\/diplomes\/(?<certification_id>\d+)\?certificateur=(?<delegate_id>\d+)/, referer) || %{}
    for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), val}
  end

end
