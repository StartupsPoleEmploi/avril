defmodule VaeWeb.Plugs.ApplicationAccess do
  @query_param "hash"

  def init(options \\ []) do
    Keyword.merge(options, [error_handler: options[:error_handler] || VaeWeb.Plugs.BrowserErrorHandler])
  end

  def call(%{params: %{"user_application_id" => application_id}} = conn, options),
    do: execute(conn, {:id, application_id}, options)

  def call(%{params: %{"id" => application_id}} = conn, options) do
    execute(conn, {:id, application_id}, options)
  end

  def call(conn, options) do
    hash_key = options[:find_with_hash]
    hash_value= Plug.Conn.get_req_header(conn, "x-hash") |> List.first() || conn.params["hash"]
    if hash_key && hash_value do
      execute(conn, {hash_key, hash_value}, options)
    else
      call_error(conn, options, :internal_server_error)
    end
  end

  def execute(conn, finder, options) do
    application = Vae.Repo.get_by(Vae.UserApplication, List.wrap(finder))
    current_user = Pow.Plug.current_user(conn)

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
      current_user.is_admin ->
        fn _a ->
          true
        end
      true -> nil
    end

    case has_access?(application, current_user, verification_func) do
      {:ok, application} ->
        Plug.Conn.assign(conn, :current_application, application)

      {:error, error} ->
        call_error(conn, options, error)
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

  defp call_error(conn, options, error) do
    IO.inspect("error")
    IO.inspect(error)
    if options[:optional] do
      conn
    else
      conn
      |> options[:error_handler].call(error)
      |> Plug.Conn.halt()
    end
  end
end
