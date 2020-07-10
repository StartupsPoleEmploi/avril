defmodule VaeWeb.Plugs.ApplicationAccess do
  alias Vae.{Repo, UserApplication, User}

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
  def define_finder(conn, %{find_with_hash: hash_key}) do
    hash_param = @hash_pairs[hash_key]
    value = conn.params[hash_param]
    {hash_key, value}
  end

  def define_finder(%Plug.Conn{params: %{"id" => id}}, _options) when not is_nil(id), do: {:id, Vae.String.to_id(id)}
  def define_finder(_conn, _options), do: nil

  def execute(conn, finder, options) do
    application = Repo.get_by(UserApplication, List.wrap(finder))
    current_user = Pow.Plug.current_user(conn)

    verification_func =
      cond do
        options[:verify_with_hash] ->
          fn a ->
            Map.get(a, options[:verify_with_hash]) == (conn.params["hash"] || conn.params["delegate_hash"])
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

  defp has_access?(%UserApplication{} = application, %User{} = user, verification_func) do
    application = application |> Repo.preload(:user)

    if (user == application.user) || user.is_admin do
      {:ok, application}
    else
      has_access?(application, nil, verification_func)
    end
  end

  defp has_access?(application, _user, verification_func) when not is_nil(verification_func) do
    if verification_func.(application) do
      {:ok, application}
    else
      {:error, :unauthorized}
    end
  end

  defp has_access?(_application, nil, nil), do: {:error, :not_authenticated}


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
