defmodule VaeWeb.Resolvers.Account do
  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.{User, Repo}

  @update_profile_error "Erreur de mise à jour du profil"
  @update_password_error "Erreur lors de la mise à jour du mot de passe"

  def identity_item(_, _, %{context: %{current_user: %User{identity: identity}}}) do
    {:ok, identity || %Vae.Identity{}}
  end

  def update_item(_, %{input: params}, %{context: %{current_user: user}}) do
    user
    |> User.changeset(%{identity: params})
    |> Repo.update()
    |> case do
      {:ok, %User{identity: identity}} -> {:ok, identity}
      {:error, changeset} ->
        error_response(@update_profile_error, changeset)
    end
  end

  def update_password(_, %{input: params}, %{context: %{current_user: user}}) do
    user
    |> User.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, %User{identity: identity}} -> {:ok, identity}
      {:error, changeset} ->
        error_response(@update_password_error, IO.inspect(changeset))

    end
  end
end
