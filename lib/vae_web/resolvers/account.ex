defmodule VaeWeb.Resolvers.Account do
  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.{Account, User, Repo}

  @update_profile_error "Erreur de mise à jour du profil"
  @update_password_error "Erreur lors de la mise à jour du mot de passe"

  def identity_item(_, _, %{context: %{current_user: %User{identity: identity}}}) do
    {:ok, identity || %Vae.Identity{}}
  end

  def update_item(_, %{input: params}, %{context: %{current_user: user}}) do
    user
    |> User.changeset(%{identity: params})
    |> Repo.update()
    # |> Account.update_identity_item(user)
    |> case do
      {:error, changeset} ->
        error_response(@update_profile_error, changeset)

      {:ok, updated_user} ->
        {:ok, Account.get_user(updated_user.id).identity}
    end
  end

  def update_password(_, %{input: params}, %{context: %{current_user: user}}) do
    user
    |> User.update_password_changeset(params)
    |> Repo.update()
    |> case do
      {:error, changeset} ->
        error_response(@update_password_error, changeset)

      {:ok, updated_user} ->
        {:ok, Account.get_user(updated_user.id).identity}
    end
  end
end
