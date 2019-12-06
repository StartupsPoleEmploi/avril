defmodule Vae.Plugs.ApplicationAccess do
  import Plug.Conn
  import Phoenix.Controller

  alias Vae.Application
  alias Vae.Repo
  alias Vae.Router.Helpers

  def init(options \\ []), do: options

  def call(%{params: %{"application_id" => application_id}} = conn, options),
    do: execute(conn, {:id, application_id}, options)

  def call(%{params: %{"id" => application_id}} = conn, options) do
    execute(conn, {:id, application_id}, options)
  end

  def call(%{params: %{"hash" => hash_value}} = conn, [find_with_hash: hash_key] = options),
    do: execute(conn, {hash_key, hash_value}, options)

  def call(conn, _params) do
    conn
    |> put_flash(:error, "Une erreur est survenue")
    |> redirect(to: Helpers.root_path(conn, :index))
    |> halt()
  end

  def execute(conn, finder, options \\ []) do
    application = Repo.get_by(Application, List.wrap(finder))

    verify_hash =
      if key = options[:verify_with_hash] || options[:find_with_hash],
        do: {key, get_in(conn, [Access.key(:params), "hash"])}

    case has_access?(conn, application, verify_hash) do
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

  defp has_access?(conn, nil, _opts), do: {:ok, nil}

  defp has_access?(conn, application, nil) do
    application = application |> Repo.preload(:user)

    if Coherence.logged_in?(conn) &&
         (Coherence.current_user(conn).id == application.user.id ||
            Coherence.current_user(conn).is_admin) do
      {:ok, application}
    else
      {:error,
       %{
         to: Helpers.session_path(conn, :new),
         msg: "Vous devez vous connecter"
       }}
    end
  end

  defp has_access?(_conn, _application, {_hash_key, nil}), do: {:ok, nil}

  defp has_access?(conn, application, {hash_key, hash_value}) do
    # && Timex.before?(Timex.today, Timex.shift(application.delegate_access_refreshed_at, days: 10))
    if Map.get(application, hash_key) == hash_value do
      {:ok, application}
    else
      {:error,
       %{
         to: Helpers.root_path(conn, :index),
         msg:
           if(Map.get(application, hash_key) == hash_value,
             do: "Accès expiré",
             else: "Vous n'avez pas accès"
           )
       }}
    end
  end
end
