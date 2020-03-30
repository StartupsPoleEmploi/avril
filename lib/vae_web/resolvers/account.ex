defmodule VaeWeb.Resolvers.Account do
  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.Account

  @update_profile_error "Erreur de mise à jour du profile"
  @update_password_error "Erreur lors de la mise à jour du mot de passe"

  def profile_item(_, _, %{context: %{current_user: user}}) do
    {:ok, to_graphql(user)}
  end

  def update_item(_, %{input: params}, %{context: %{current_user: user}}) do
    params
    |> from_graphql()
    |> Account.update_profile_item(user)
    |> case do
      {:error, changeset} ->
        error_response(@update_profile_error, changeset)

      {:ok, user} ->
        {:ok, to_graphql(user)}
    end
  end

  def update_password(_, %{input: params}, %{context: %{current_user: user}}) do
    case Vae.Account.update_user_password(user, params) do
      {:error, changeset} ->
        error_response(@update_password_error, changeset)

      {:ok, user} ->
        {:ok, to_graphql(user)}
    end
  end

  defp to_graphql(user) do
    user
    |> put_full_address()
    |> put_birth_place()
  end

  defp put_full_address(user) do
    Map.put(user, :full_address, %{
      city: user.city_label,
      country: user.country_label,
      postal_code: user.postal_code,
      street: Account.address_street(user)
    })
  end

  defp put_birth_place(user) do
    Map.put(user, :birth_place, %{city: user.birth_place})
  end

  defp from_graphql(params) do
    params
    |> get_user_params()
    |> maybe_flatten_address(params[:full_address])
    |> maybe_flatten_birth_place(params[:birth_place])
  end

  defp get_user_params(params) do
    Map.take(params, [
      :gender,
      :birthday,
      :first_name,
      :last_name,
      :email,
      :phone_number
    ])
  end

  defp maybe_flatten_address(user_params, nil), do: user_params

  defp maybe_flatten_address(user_params, full_address) do
    user_params
    |> maybe_flatten_city_label(full_address[:city])
    |> maybe_flatten_country_label(full_address[:country])
    |> maybe_flatten_postal_code(full_address[:postal_code])
    |> maybe_reset_street_address(full_address[:street])
  end

  defp maybe_flatten_city_label(user_params, nil), do: user_params

  defp maybe_flatten_city_label(user_params, city),
    do: Map.merge(user_params, %{city_label: city})

  defp maybe_flatten_country_label(user_params, nil), do: user_params

  defp maybe_flatten_country_label(user_params, country),
    do: Map.merge(user_params, %{country_label: country})

  defp maybe_flatten_postal_code(user_params, nil), do: user_params

  defp maybe_flatten_postal_code(user_params, postal_code),
    do: Map.merge(user_params, %{postal_code: postal_code})

  defp maybe_reset_street_address(user_params, nil), do: user_params

  defp maybe_reset_street_address(user_params, street_address) do
    Map.merge(user_params, %{
      address1: street_address,
      address2: "",
      address3: "",
      address4: ""
    })
  end

  defp maybe_flatten_birth_place(user_params, nil), do: user_params

  defp maybe_flatten_birth_place(user_params, %{city: city}) do
    Map.merge(user_params, %{birth_place: city})
  end
end
