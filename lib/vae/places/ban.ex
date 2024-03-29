defmodule Vae.Places.Ban do
  require Logger

  @base_url "https://api-adresse.data.gouv.fr/search/"

  def get_geoloc_from_address(address) do
    fetch_ban_api(%{q: address, type: :housenumber, limit: 1}) || fetch_ban_api(%{q: address, type: :street, limit: 1})
  end

  def search_geoloc_from_address(address) do
    fetch_ban_api(%{q: address, type: :housenumber})
  end

  def get_geoloc_from_city(city) do
    fetch_ban_api(%{q: city, type: :municipality, limit: 1})
  end

  def search_geoloc_from_city(city) do
    fetch_ban_api(%{q: city, type: :municipality})
  end

  def get_geoloc_from_postal_code(postal_code) do
    fetch_ban_api(%{q: postal_code, postcode: postal_code, type: :municipality, limit: 1})
  end

  def search_geoloc_from_postal_code(postal_code) do
    fetch_ban_api(%{q: postal_code, postcode: postal_code, type: :municipality})
  end

  def get_field(%{"geometry" => %{"coordinates" => [lng, lat]}}, :lng_lat), do: {lng, lat}
  def get_field(%{"geometry" => %{"coordinates" => [lng, _lat]}}, :lng), do: lng
  def get_field(%{"geometry" => %{"coordinates" => [_lng, lat]}}, :lat), do: lat
  def get_field(%{"properties" => %{"city" => city}}, :city), do: city
  def get_field(%{"properties" => %{"postcode" => postal_code}}, :postal_code), do: postal_code
  def get_field(%{"properties" => %{"context" => context}}, :administrative) do
    String.split(context, ", ", parts: 3)
    |> Enum.reverse()
    |> List.first()
  end

  def get_field(_, _), do: nil

  defp fetch_ban_api(%{q: q} = query) when not is_nil(q) do
    with {:ok, response} <- HTTPoison.get("#{@base_url}?#{URI.encode_query(query)}"),
         {:ok, %{
            "attribution" => "BAN",
            "features" => results
          }} <- response.body |> Jason.decode() do
      if query.limit == 1 do
        List.first(results)
      else
        results
      end
    else
      {:ok, %{"code" => 500, "message" => message}} ->
        Logger.error(fn -> inspect(message) end)
        empty_result(query)

      {:error, reason} ->
        Logger.error(fn -> inspect(reason) end)
        empty_result(query)
    end
  end
  defp fetch_ban_api(query), do: empty_result(query)

  defp empty_result(query) do
    if query.limit == 1, do: nil, else: []
  end
end