defmodule Vae.EctoDbSession do
  require Logger
  import Ecto.Query

  @session_model Application.get_env(:coherence, :session_model)
  @session_repo  Application.get_env(:coherence, :session_repo)

  def get_user_data(repo, user, creds, id_key) do
    @session_model
    |> where([s], s.token == ^creds)
    |> @session_repo.one
    |> case do
      nil -> nil
      session ->
        user_id = get_id user, id_key, session.user_id

        session.user_type
        |> String.to_atom
        |> where([u], field(u, ^id_key) == ^user_id)
        |> repo.one
    end
  end

  def put_credentials(_repo, user, creds, id_key) do
    id_str = "#{Map.get user, id_key}"
    params = %{
      token: creds,
      user_type: Atom.to_string(user.__struct__),
      user_id: id_str
    }

    where(@session_model, [s], s.user_id == ^id_str)
    |> @session_repo.delete_all

    @session_model.changeset(@session_model.__struct__, params)
    |> @session_repo.insert
    |> case do
      {:ok, _} -> :ok
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_credentials(_user, creds) do
    @session_model
    |> where([s], s.token == ^creds)
    |> @session_repo.one
    |> case do
      nil ->
        nil
      user ->
        @session_repo.delete user
    end
  end

  def delete_user_logins(_user) do
    from(p in @session_model) |> @session_repo.delete_all
  end

  # handle converting the users id into correct model type
  defp get_id(user, id_key, user_id) do
    case user.__struct__.__schema__(:type, id_key) do
      int when int in [:integer, :id] ->
        String.to_integer user_id
      :string ->
        user_id
    end
  end
end