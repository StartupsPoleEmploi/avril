defmodule Vae.AuthController do
  use Vae.Web, :controller

  alias Vae.OAuth
  alias Vae.OAuth.Clients
  alias Vae.User
  alias Vae.Application
  alias Vae.Delegate

  def save_session_and_redirect(conn, _params) do
    referer = hd(get_req_header(conn, "referer"))

    client = OAuth.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = OAuth.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state} = _params) do
    client = Clients.get_client(state)
    client_with_token = OAuth.generate_access_token(client, code)

    conn =
      conn
      |> put_session(:pe_access_token, client_with_token.token.access_token)

    userinfo_api_result =
      OAuth.get(
        client_with_token,
        "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo"
      )

    user_status =
      case Repo.get_by(User, pe_id: userinfo_api_result.body["idIdentiteExterne"]) do
        nil -> User.create_or_associate_with_pe_connect_data(userinfo_api_result.body)
        user -> {:ok, user}
      end
      |> User.fill_with_api_fields(client_with_token, 3)

    application_status =
      case user_status do
        {:ok, user} ->
          user = Repo.preload(user, :current_application)
          {:ok,
           {user,
            Application.find_or_create_with_params(
              Map.merge(
                get_certification_id_and_delegate_id_from_referer(get_session(conn, :referer)),
                %{user_id: user.id}
              )
            ) || user.current_application}}

        error -> error
      end

    case application_status do
      {:ok, {user, nil}} ->
        Coherence.Authentication.Session.create_login(conn, user)
        |> put_flash(:info, "Sélectionnez un diplôme pour poursuivre.")
        |> redirect(to: Routes.root_path(conn, :index))

      {:ok, {user, application}} ->
        Coherence.Authentication.Session.create_login(conn, user)
        |> redirect(to: Routes.application_path(conn, :show, application))

      {:error, msg} ->
        conn
        |> put_flash(:error, inspect(msg) || "Une erreur est survenue. Veuillez réessayer plus tard.")
        |> redirect(external: get_session(conn, :referer))
    end
  end

  def callback(conn, params) do
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
end
