defmodule Vae.Account do
  alias Vae.Repo
  alias Vae.Account.Identity
  alias Vae.User

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def get_user_by_pe(pe_id) do
    Repo.get_by(User, pe_id: pe_id)
  end

  def address_street(user) do
    [user.address1, user.address2, user.address3, user.address4]
    |> Vae.Enum.join_keep_nil(", ")
  end

  def update_identity(attrs \\ %{}, %User{} = user) do
    user
    |> User.update_identity_changeset(attrs)
    |> Repo.update!()
  end

  def update_identity_item(attrs \\ %{}, %User{} = user) do
    user
    |> User.update_identity_changeset(attrs)
    |> Repo.update()
  end

  def update_profile_item(attrs \\ %{}, %User{} = user) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def update_user_password(%User{} = user, attrs) do
    User.update_password_changeset(user, attrs)
    |> Repo.update()
  end

  def validate_required_fields_to_register_meeting(user) do
    changeset = User.register_fields_required_changeset(user)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def create_user_from_pe(user_info) do
    user_info
    |> User.create_user_from_pe_changeset()
    |> Repo.insert()
  end

  def maybe_update_user_from_pe(user, user_info) do
    user
    |> User.update_user_from_pe_changeset(user_info)
    |> Repo.update()
  end

  def complete_user_profile({:ok, _user} = upsert, token) do
    {:ok, user} = fill_with_api_fields(upsert, token)
    identity_params = %{identity: Identity.from_user(user)}

    User.update_identity_changeset(user, identity_params)
    |> Repo.update()
  end

  def fill_with_api_fields({:ok, user} = initial_status, client_with_token) do
    user
    |> Map.from_struct()
    |> Vae.PoleEmploi.fetch_all(client_with_token)
    |> Enum.reduce(initial_status, fn
      map, user when map == %{} ->
        user

      data, {:ok, user} ->
        User.update_changeset(user, data)
        |> Repo.update()

      _data, {:error, _changeset} ->
        {:ok, get_user(user.id)}
    end)
  end
end
