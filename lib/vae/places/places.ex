defmodule Vae.Places do
  defdelegate get_geoloc_from_address(address), to: Vae.Places.Client.Algolia

  defdelegate get_geoloc_from_postal_code(postal_code), to: Vae.Places.Cache

  def get_city(geolocation) do
    case get_cities(geolocation) do
      nil -> nil
      c -> List.first(c)
    end
  end

  def get_cities(%{"is_city" => true} = params), do: params["locale_names"]
  def get_cities(params), do: params["city"]

  def get_administrative(%{"administrative" => administrative}) when not is_nil(administrative),
    do: List.first(administrative)

  def get_administrative(_), do: nil
end
