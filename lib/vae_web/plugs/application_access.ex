defmodule VaeWeb.Plugs.ApplicationAccess do
  @hash_pairs [booklet_hash: "hash", delegate_access_hash: "delegate_hash"]

  def init(options \\ []) do
    Keyword.merge(options,
      error_handler: options[:error_handler] || VaeWeb.Plugs.ErrorHandlers.Browser
    )
  end

  def call(conn, options) do
    finder = define_finder(conn, Enum.into(options, %{}))
    if finder do
      execute(conn, finder, options)
    else
      call_error(conn, options, :internal_server_error)
    end
  end

  def define_finder(conn, options \\ %{})
  def define_finder(conn, %{find_with_hash: true}) do
    Enum.find_value(@hash_pairs, fn {field, query} ->
      value = Plug.Conn.get_req_header(conn, "x-#{String.replace(query, "_", "-")}") |> List.first() || conn.params[query]
      if value, do: {field, value}
    end)
  end

  def define_finder(%Plug.Conn{params: %{"id" => id}}, _options) when not is_nil(id), do: {:id, id}
  def define_finder(%Plug.Conn{params: %{"user_application_id" => id}}, _options)  when not is_nil(id), do: {:id, id}
  def define_finder(_conn, _options), do: nil

  def execute(conn, finder, options) do
    application = Vae.Repo.get_by(Vae.UserApplication, List.wrap(finder))
    current_user = Pow.Plug.current_user(conn)

    verification_func =
      cond do
        options[:verify_with_hash] ->
          fn a ->
            Map.get(a, options[:verify_with_hash]) == (conn.params["hash"] || conn.params["delegate_hash"])
          end

        conn.assigns[:server_side_authenticated] || options[:find_with_hash] ->
          fn _a ->
            true
          end

        true ->
          nil
      end

    case has_access?(application, current_user, verification_func) do
      {:ok, application} ->
        Plug.Conn.assign(conn, :current_application, application)

      {:error, error} ->
        call_error(conn, options, error)
    end
  end

  defp has_access?(nil, _user, _verification), do: {:error, :not_found}

  defp has_access?(application, _user, verification_func) when not is_nil(verification_func) do
    if verification_func.(application) do
      {:ok, application}
    else
      {:error, :unauthorized}
      # has_access?(application, user, nil)
    end
  end

  defp has_access?(_application, nil, _verification_func), do: {:error, :not_authenticated}

  defp has_access?(application, user, _verification_func) do
    application = application |> Vae.Repo.preload(:user)

    if user && (user == application.user || user.is_admin) do
      {:ok, application}
    else
      {:error, :unauthorized}
    end
  end

  defp call_error(conn, options, error) do
    if options[:optional] do
      conn
    else
      conn
      |> options[:error_handler].call(error)
      |> Plug.Conn.halt()
    end
  end
end
