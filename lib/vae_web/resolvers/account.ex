defmodule VaeWeb.Resolvers.Account do
  alias Vae.Account

  def profile_item(_, _, %{context: %{current_user: user}}) do
    {:ok, to_graphql(user)}
  end

  def update_item(_, %{input: params}, %{context: %{current_user: user}}) do
    params
    |> from_graphql()
    |> Account.update_profile_item(user)
    |> case do
      {:error, _} ->
        {:error, "Erreur de mise à jour du profile"}

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
    |> flatten_address(params)
    |> flatten_birth_place(params)
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

  defp flatten_address(user_params, params) do
    Map.merge(user_params, %{
      city_label: params[:full_address][:city],
      country_label: params[:full_address][:country],
      postal_code: params[:full_address][:postal_code]
    })
    |> maybe_reset_street_address(params[:full_address][:street])
  end

  defp maybe_reset_street_address(user_params, nil), do: user_params

  defp maybe_reset_street_address(user_params, street_address) do
    Map.merge(user_params, %{
      address1: street_address,
      address2: "",
      address3: "",
      address4: ""
    })
  end

  defp flatten_birth_place(user_params, params) do
    Map.merge(user_params, %{birth_place: params[:birth_place][:city]})
  end
end
