defmodule VaeWeb.Resolvers.Account do
  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.Account

  @update_profile_error "Erreur de mise à jour du profile"
  @update_password_error "Erreur lors de la mise à jour du mot de passe"

  def identity_item(_, _, %{context: %{current_user: user}}) do
    {:ok, user.identity || %Vae.Identity{}}
  end

  def update_item(_, %{input: params}, %{context: %{current_user: user}}) do
    %{identity: params}
    |> Account.update_identity_item(user)
    |> case do
      {:error, changeset} ->
        error_response(@update_profile_error, changeset)

      {:ok, updated_user} ->
        {:ok, Account.get_user(updated_user.id).identity}
    end
  end

  def update_password(_, %{input: params}, %{context: %{current_user: user}}) do
    case Account.update_user_password(user, params) do
      {:error, changeset} ->
        error_response(@update_password_error, changeset)

      {:ok, updated_user} ->
        {:ok, Account.get_user(updated_user.id).identity}
    end
  end
end
