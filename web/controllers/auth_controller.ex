defmodule Vae.AuthController do
  use Vae.Web, :controller

  alias Vae.Authentication
  alias Vae.Authentication.Clients

  def save_session_and_redirect(conn, params) do
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

    IO.inspect(state)
    IO.puts '===================================='
    IO.inspect(code)
    IO.puts '===================================='
    IO.inspect(client)
    IO.puts '===================================='
    IO.inspect(client_with_token)
    IO.puts '===================================='

    resource_1 =
      Authentication.get(
        client_with_token,
        "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees"
      )

    resource_2 =
      Authentication.get(
        client_with_token,
        "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences"
      )

    resource_3 =
      Authentication.get(
        client_with_token,
        "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences"
      )

    IO.inspect(conn)

    redirect(conn, external: get_session(conn, :referer))
    # conn
  end
end
