defmodule Vae.Account do
  alias Vae.Repo
  alias Vae.User

  def get_user(user_id) do
    Repo.get(User, user_id)
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

  def update_profile_item(attrs \\ %{}, %User{} = user) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def update_user_password(%User{} = user, attrs) do
    User.update_password_changeset(user, attrs)
    |> Repo.update()
  end
end
