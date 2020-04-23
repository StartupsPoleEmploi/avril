defmodule VaeWeb.AuthController do
  use VaeWeb, :controller

  require Logger

  alias Vae.Account
  alias Vae.PoleEmploi
  alias Vae.PoleEmploi.OAuth
  alias Vae.PoleEmploi.OAuth.Clients
  alias VaeWeb.Pow.Routes, as: PowRoutes

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
        nil -> Account.create_user_from_pe(user_info)
        user -> Account.maybe_update_user_from_pe(user, user_info)
      end
      |> Account.complete_user_profile(token)
      |> case do
        {:ok, upserted_user} ->
          Pow.Plug.create(conn, upserted_user)
          |> PowRoutes.maybe_create_application_and_redirect()

        {:error, changeset} ->
          handle_error(conn, changeset)
      end
    else
      {:error, _error} ->
        handle_error(conn)
    end
  end

  def callback(conn, _params) do
    redirect(conn, external: get_session(conn, :referer))
  end

  defp handle_error(conn, msg \\ "Une erreur est survenue. Veuillez réessayer plus tard.")

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
    |> redirect(external: get_session(conn, :referer))
  end
end
