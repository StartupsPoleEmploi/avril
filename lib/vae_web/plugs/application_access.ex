defmodule VaeWeb.Plugs.ApplicationAccess do
  @query_param "hash"

  def init(options \\ []) do
    Keyword.merge(options, [error_handler: options[:error_handler] || VaeWeb.Plugs.BrowserErrorHandler])
  end

  def call(%{params: %{"application_id" => application_id}} = conn, options),
    do: execute(conn, {:id, application_id}, options)

  def call(%{params: %{"id" => application_id}} = conn, options) do
    execute(conn, {:id, application_id}, options)
  end

  def call(%{params: %{@query_param => hash_value}} = conn, [find_with_hash: hash_key] = options),
    do: execute(conn, {hash_key, hash_value}, options)

  def call(conn, [error_handler: handler]) do
    conn
    |> handler.call(:internal_server_error)
    |> Plug.Conn.halt()
  end

  def execute(conn, finder, options) do
    application = Vae.Repo.get_by(Vae.UserApplication, List.wrap(finder))
    current_user = Pow.Plug.current_user(conn)

    IO.inspect("##############################")
    IO.inspect("##############################")
    IO.inspect(conn.assigns)
    IO.inspect("##############################")
    IO.inspect("##############################")

    verification_func = cond do
      conn.assigns[:server_side_authenticated] ->
        fn _a ->
          true
        end
      options[:verify_with_hash] ->
        fn a ->
          Map.get(a, options[:verify_with_hash]) ==
          get_in(conn, [Access.key(:params), @query_param])
        end
    end

    case has_access?(application, current_user, verification_func) do
      {:ok, application} ->
        Plug.Conn.assign(conn, :current_application, application)

      {:error, error} ->
        conn
        |> options[:error_handler].call(error)
        |> Plug.Conn.halt()
    end
  end

  defp has_access?(nil, _user, _verification), do: {:error, :not_found}
  defp has_access?(application, user, verification_func) when not is_nil(verification_func) do
    if verification_func.(application) do
      {:ok, application}
    else
      has_access?(application, user, nil)
    end
  end
  defp has_access?(_application, nil, _verification_func), do: {:error, :not_authenticated}
  defp has_access?(application, user, _verification_func) do
    application = application |> Vae.Repo.preload(:user)

    if user == application.user || user.is_admin do
      {:ok, application}
    else
      {:error, :unauthorized}
    end
  end
end
