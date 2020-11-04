defmodule VaeWeb.AuthController do
  use VaeWeb, :controller

  require Logger

  alias Vae.Account
  alias Vae.PoleEmploi
  alias Vae.PoleEmploi.OAuth
  alias Vae.PoleEmploi.OAuth.Clients

  def save_session_and_redirect(conn, _params) do
    referer = List.first(get_req_header(conn, "referer"))

    client = OAuth.init_client()

    {:ok, client} = Clients.add_client(client, client.params[:state], client.params[:nonce])

    url = OAuth.get_authorize_url!(client)

    put_session(conn, :referer, referer)
    |> redirect(external: url)
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    with {:ok, {token, user_info}} <- PoleEmploi.get_user_info(state, code) do
      case Account.get_user_by_pe(user_info["idIdentiteExterne"]) do
        nil ->
          user_info
          |> Account.create_user_from_pe()
          |> Account.complete_user_profile(token)

        user ->
          {:ok, user}
      end
      |> case do
        {:ok, upserted_user} ->
          conn = Pow.Plug.create(conn, upserted_user)

          if get_session(conn, :referer) == Routes.user_url(conn, :eligibility) do
            redirect_to_referer(conn)
          else
            VaeWeb.RegistrationController.maybe_create_application_and_redirect(conn)
          end

        {:error, changeset} ->
          handle_error(conn, changeset)
      end
    else
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)
        handle_error(conn)
    end
  end

  def callback(conn, _params) do
    redirect_to_referer(conn)
  end

  defp handle_error(conn, msg \\ "Une erreur est survenue. Veuillez réessayer plus tard.")

  defp handle_error(
         conn,
         %Ecto.Changeset{errors: [email: {"has already been taken", _opts}]}
       ) do
    handle_error(
      conn,
      "Votre email est déjà associé à un compte Avril. Connectez-vous avec votre adresse email + mot de passe."
    )
  end

  defp handle_error(
         conn,
         %Ecto.Changeset{errors: [email: {"can't be blank", _opts}]}
       ) do
    handle_error(
      conn,
      "Il semblerait que vous n'ayez pas confirmé votre adresse email auprès de Pôle emploi. Merci de revenir une fois cette opération effectuée."
    )
  end

  defp handle_error(conn, %Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      error =
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)

      Logger.error(fn -> inspect(error) end)
    end)

    handle_error(conn)
  end

  defp handle_error(conn, msg) do
    conn
    |> put_flash(:danger, if(is_binary(msg), do: msg, else: inspect(msg)))
    |> redirect(external: redirect_url(conn))
  end

  defp redirect_to_referer(conn) do
    conn
    |> redirect(external: redirect_url(conn))
  end

  defp redirect_url(conn) do
    with url when not is_nil(url) <- get_session(conn, :referer) do
      url
    else
      nil -> Routes.root_url(conn, :index)
    end
  end
end
