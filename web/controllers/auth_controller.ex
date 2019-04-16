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

    user_status = case Repo.get_by(User, pe_id: userinfo_api_result.body["idIdentiteExterne"]) do
      nil -> User.create_or_associate_with_pe_connect_data(userinfo_api_result.body)
      user -> {:ok, user |> Repo.preload(:current_application)}
    end
    |> User.fill_with_api_fields(client_with_token, 3)

    application_status = case user_status do
      {:ok, user} ->
        {:ok, {user, Application.find_or_create_with_params(
          Map.merge(
            get_certification_id_and_delegate_id_from_referer(get_session(conn, :referer)),
            %{user_id: user.id}
          )
        ) || user.current_application }}
      error -> IO.inspect(error)
    end

    case application_status do
      {:ok, {user, nil}} ->
        Coherence.Authentication.Session.create_login(conn, user)
        |> put_flash(:info, "Sélectionnez un diplôme pour poursuivre.")
        |> redirect(to: root_path(conn, :index))
      {:ok, {user, application}} ->
        message = if is_nil(application.submitted_at) do
          "Bienvenue sur votre page de candidat. Vous pouvez consulter vos informations avant de les soumettre au certificateur."
        else
          "Bienvenue sur votre page de candidat."
        end
        Coherence.Authentication.Session.create_login(conn, user)
        |> put_flash(:success, message)
        |> redirect(to: application_path(conn, :show, application))
      {:error, msg} ->
        conn
        |> put_flash(:error, msg || "Une erreur est survenue. Veuillez réessayer plus tard.")
        |> redirect(external: get_session(conn, :referer))
    end
  end

  defp get_certification_id_and_delegate_id_from_referer(referer) do
    string_key_map = Regex.named_captures(~r/\/diplomes\/(?<certification_id>\d+)\?certificateur=(?<delegate_id>\d+)/, referer) || %{}
    for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), val}
  end

end
