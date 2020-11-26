defmodule Vae.Account do
  alias Vae.Repo
  alias Vae.Identity
  alias Vae.Booklet.Address
  alias Vae.User

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def get_user_by_pe(pe_id) do
    Repo.get_by(User, pe_id: pe_id)
  end

  def update_identity_item(attrs \\ %{}, %User{} = user) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def validate_required_fields_to_register_meeting(user) do
    changeset = User.register_identity_fields_required_changeset(user)

    if changeset.valid? do
      {:ok, changeset}
    else
      {:error, changeset}
    end
  end

  def complete_user_profile({:error, _} = error, _token), do: error

  def complete_user_profile({:ok, _user} = upsert, token) do
    {:ok, user} = fill_with_api_fields(upsert, token)

    user
    |> IO.inspect()
    |> User.changeset(%{identity: IO.inspect(Identity.from_user(user))})
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
        user
        |> User.changeset(data)
        |> Repo.update()

      _data, {:error, _changeset} ->
        {:ok, get_user(user.id)}
    end)
  end

  def fullname(%{identity: identity}), do: Identity.fullname(identity)
  def fullname(user), do: Identity.fullname(user)
  def formatted_email(user), do: Identity.formatted_email(user)
  def address_city(%{identity: %{full_address: address}}), do: Address.address_city(address)
  def address_city(%{full_address: address}), do: Address.address_city(address)

  def address_street(%User{} = user) do
    [user.address1, user.address2, user.address3, user.address4]
    |> Vae.Enum.join_keep_nil(", ")
  end

  def address_street(address), do: address.street
end
