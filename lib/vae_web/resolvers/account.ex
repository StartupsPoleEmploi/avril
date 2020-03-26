defmodule VaeWeb.Resolvers.Account do
  def profile_item(_, _, %{context: %{current_user: user}}) do
    {:ok, to_graphql(user)}
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
      street: Vae.User.address_street(user)
    })
  end

  defp put_birth_place(user) do
    Map.put(user, :birth_place, %{city: user.birth_place})
  end
end
