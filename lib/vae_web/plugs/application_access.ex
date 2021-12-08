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
            hash_param = @hash_pairs[options[:verify_with_hash]]
            hash_param_value = conn.params[hash_param] || conn.params["hash"] # "hash" is legacy
            application_hash_value = Map.get(a, options[:verify_with_hash])

            not is_nil(application_hash_value) && application_hash_value == hash_param_value
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

  defp has_access?(
    %UserApplication{user_id: user_id, delegate_id: delegate_id} = application,
    %User{id: current_user_id, is_admin: current_user_admin, is_delegate: current_user_delegate} = user,
    verification_func
  ) do
    cond do
      current_user_id == user_id -> {:ok, application}
      current_user_admin ->  {:ok, application}
      current_user_delegate and delegate_id in Vae.User.delegate_ids(user) ->
        {:ok, application}
      true ->
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
