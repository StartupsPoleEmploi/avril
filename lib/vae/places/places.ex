defmodule Vae.Places do
  @places_client Application.get_env(:vae, :places_client)
  @places_cache Application.get_env(:vae, :places_cache)

  defdelegate get_geoloc_from_address(address), to: @places_client

  defdelegate get_geoloc_from_postal_code(postal_code), to: @places_cache

  defdelegate get_geoloc_from_city(city), to: @places_client

  defdelegate get_geoloc_from_geo(geo), to: @places_client

  def get_city(geolocation) do
    case get_cities(geolocation) do
      nil -> nil
      c -> List.first(c)
    end
  end

  def get_administrative_from_postal_code(postal_code) do
    postal_code
    |> __MODULE__.get_geoloc_from_postal_code()
    |> get_administrative()
  end

  def get_cities(%{"is_city" => true} = params), do: params["locale_names"]
  def get_cities(params), do: params["city"]

  def get_administrative(%{"administrative" => administrative}) when not is_nil(administrative),
    do: List.first(administrative)

  def get_administrative(_), do: nil
end
