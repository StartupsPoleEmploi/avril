defmodule VaeWeb.AuthController do
  use VaeWeb, :controller

  require Logger

  alias Vae.{Account, OAuth, User}
  alias Vae.OAuth.Clients
  alias VaeWeb.Pow.Routes, as: PowRoutes

  @user_info_endpoint "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo"

  def save_session_and_redirect(conn, _params) do
    referer = List.first(get_req_header(conn, "referer"))

    client = OAuth.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = OAuth.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    with {:ok, user_info} <- get_user_info(state, code) do
      case Account.get_user_by_pe(user_info["idIdentiteExterne"]) do
        nil -> Account.create_user_from_pe(user_info)
        user -> Account.maybe_update_user_from_pe(user, user_info)
      end
    else
      {:error, _error} ->
        handle_error(conn)
    end
  end

  def get_user_info(state, code) do
    with(
      client <- Clients.get_client(state),
      {:ok, client_with_token} <- OAuth.generate_access_token(client, code),
      %OAuth2.Response{body: user_info_response} <-
        OAuth.get(
          client_with_token,
          @user_info_endpoint
        )
    ) do
      {:ok, user_info_response}
    else
      error ->
        Logger.error(fn -> inspect(error) end)
        {:error, error}
    end
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    client = Clients.get_client(state)

    with(
      {:ok, client_with_token} <- OAuth.generate_access_token(client, code),
      %OAuth2.Response{body: userinfo_api_result_body} <-
        OAuth.get(
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
          |> PowRoutes.maybe_create_application_and_redirect()

        {:error, msg} ->
          handle_error(conn, msg)
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
    |> put_flash(:danger, if(is_binary(msg), do: msg, else: inspect(msg)))
    |> redirect(external: get_session(conn, :referer))
  end
end
