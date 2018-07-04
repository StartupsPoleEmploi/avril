defmodule Vae.AlgoliaPlaces do
  require Logger

  @algolia_places_query "https://places-dsn.algolia.net/1/places/query"
  @algolia_places_keys ~w(_geoloc country_code country administrative county city postcode locale_names _tags is_city)

  def get_first_hit_to_index(query) do
    query
    |> get_first_hit()
    |> Map.take(@algolia_places_keys)
  end

  def get_first_hit(query) do
    with {:ok, result} <- get(query), hits <- Map.get(result, "hits"), first_hit <- List.first(hits) do
      first_hit
    else
      {_, error} -> Logger.warn(fn -> error end)
    end
  end

  def get(query) do
    {app_id, api_key} = Vae.PlacesLoadBalancer.get_index()
    algolia_headers = [
      {"Content-type", "application/json"},
      {"X-Algolia-Application-Id", app_id},
      {"X-Algolia-API-Key", api_key}
    ]
    with {:ok, body} <-
           Poison.encode(%{query: query, language: "fr", countries: ["fr"], hitsPerPage: 1}),
         {:ok, response} <- HTTPoison.post(@algolia_places_query, body, algolia_headers) do
      Poison.decode(response.body)
    else
      {_, error} ->
        Logger.warn(fn -> error end)
        {:error, error}
    end
  end

  def get_city(geolocation) do
    case get_cities(geolocation) do
      nil -> nil
      c -> List.first(c)
    end
  end

  def get_cities(%{"is_city" => true} = params), do: params["locale_names"]
  def get_cities(params), do: params["city"]

  def get_administrative(%{"administrative" => administrative}) when not is_nil(administrative), do: List.first(administrative)
  def get_administrative(_), do: nil
end
