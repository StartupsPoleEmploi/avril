defmodule Vae.Plugs.ApplicationAccess do
  import Plug.Conn
  import Phoenix.Controller

  alias Vae.Application
  alias Vae.Repo
  alias Vae.Router.Helpers

  def init(params), do: params

  def call(%{params: %{"id" => application_id}} = conn, params),
    do: execute(conn, application_id, params)

  def call(%{params: %{"application_id" => application_id}} = conn, params),
    do: execute(conn, application_id, params)

  def call(conn, _params) do
    conn
    |> put_flash(:error, "Une erreur est survenue")
    |> redirect(to: Helpers.root_path(conn, :index))
    |> halt()
  end

  def execute(conn, application_id, options \\ []) do
    application =
      case Repo.get(Application, application_id) do
        nil -> nil
        application -> Repo.preload(application, :user)
      end

    hash = if options[:allow_hash_access], do: get_in(conn, [Access.key(:params), "hash"])

    case has_access?(conn, application, hash) do
      {:ok, nil} ->
        conn
        |> put_status(:not_found)
        |> put_view(Vae.ErrorView)
        |> render("404.html", layout: false)
        |> halt()

      {:ok, application} ->
        Plug.Conn.assign(conn, :current_application, application)

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
        |> halt()
    end
  end

  defp has_access?(_conn, nil, _hash), do: {:ok, nil}

  defp has_access?(conn, application, nil) do
    if Coherence.logged_in?(conn) &&
         (Coherence.current_user(conn).id == application.user.id ||
            Coherence.current_user(conn).is_admin) do
      {:ok, application}
    else
      {:error,
       %{
         to: Helpers.session_path(conn, :new, %{"mode" => "pe-connect"}),
         msg: "Vous devez vous connecter"
       }}
    end
  end

  defp has_access?(conn, application, hash) do
    # && Timex.before?(Timex.today, Timex.shift(application.delegate_access_refreshed_at, days: 10))
    if application.delegate_access_hash == hash do
      {:ok, application}
    else
      {:error,
       %{
         to: Helpers.root_path(conn, :index),
         msg:
           if(application.delegate_access_hash == hash,
             do: "Accès expiré",
             else: "Vous n'avez pas accès"
           )
       }}
    end
  end
end
