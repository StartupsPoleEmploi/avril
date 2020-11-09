defmodule Vae.Places.Client.Algolia do
  require Logger

  @behaviour Vae.Places.Client

  @url_places "https://status.algolia.com/1/usage/total_read_operations/period/month/places"

  @algolia_places_query "https://places-dsn.algolia.net/1/places/query"
  @algolia_places_query_options %{language: "fr", countries: ["fr"], hitsPerPage: 1}
  @algolia_places_reverse "https://places-dsn.algolia.net/1/places/reverse"
  @algolia_places_keys ~w(_geoloc country_code country administrative county city postcode locale_names _tags is_city)
  @algolia_places_reverse_options %{language: "fr", hitsPerPage: 1}

  # ------------------------#
  #          Search        #
  # ------------------------#

  def get_geoloc_from_postal_code(postal_code) do
    get(%{query: postal_code}, @algolia_places_query)
  end

  def get_geoloc_from_city(city) do
    get(%{query: city}, @algolia_places_query)
  end

  def get_geoloc_from_address(address) when address in [nil, ""], do: nil

  def get_geoloc_from_address(address) do
    get(%{query: address}, @algolia_places_query)
  end

  def get_geoloc_from_geo(%{"lat" => lat, "lng" => lng}) do
    get(%{aroundLatLng: "#{lat},#{lng}"}, @algolia_places_reverse)
  end

  defp get(query, endpoint) do
    query
    |> get_first_hit(endpoint)
    |> case do
      nil ->
        nil

      places ->
        Map.take(places, @algolia_places_keys)
    end
  end

  defp get_first_hit(query, endpoint) do
    with {:ok, result} <- execute(query, endpoint),
         hits when not is_nil(hits) <- Map.get(result, "hits"),
         first_hit <- List.first(hits) do
      first_hit
    else
      {_, error} -> Logger.warn(fn -> error end)
    end
  end

  defp execute(query, @algolia_places_query) do
    with headers <- build_headers(),
         {:ok, body} <-
           query
           |> Map.merge(@algolia_places_query_options)
           |> Poison.encode(),
         {:ok, response} <- HTTPoison.post(@algolia_places_query, body, headers) do
      Poison.decode(response.body)
    else
      {_, error} ->
        Logger.warn(fn -> error end)
        {:error, error}
    end
  end

  defp execute(query, @algolia_places_reverse) do
    params = Map.merge(query, @algolia_places_reverse_options)

    with headers <- build_headers(),
         {:ok, response} <- HTTPoison.get(@algolia_places_reverse, headers, params: params) do
      Poison.decode(response.body)
    else
      {_, error} ->
        Logger.warn(fn -> error end)
        {:error, error}
    end
  end

  defp build_headers() do
    [
      {"Content-type", "application/json"},
      {"X-Algolia-Application-Id", get_algolia_app_id()},
      {"X-Algolia-API-Key", get_algolia_api_key()}
    ]
  end

  def get_algolia_app_id(), do: get_config(:algolia_places_app_id)
  def get_algolia_api_key(), do: get_config(:algolia_places_api_key)

  def get_config(:algolia_places_app_id), do: Application.get_env(:algolia, :places_app_id)
  def get_config(:algolia_places_api_key), do: Application.get_env(:algolia, :places_api_key)

  # ------------------------#
  #         STATS          #
  # ------------------------#

  def current_month_stats({credentials, index}) do
    {index, get_stats(credentials)}
  end

  defp get_stats({app_id, %{monitoring: monitoring_api_key, search: _search_api_key}}) do
    headers = ["X-Algolia-Application-Id": app_id, "X-Algolia-API-Key": monitoring_api_key]
    %Date{month: current_month} = Date.utc_today()

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(@url_places, headers),
         {:ok, json} <- body |> Poison.decode() do
      json
      |> Map.get("total_read_operations")
      |> Enum.filter(&is_same_month?(&1, current_month))
      |> Enum.reduce(0, &add(&1, &2))
    end
  end

  defp is_same_month?(%{"t" => t, "v" => _v}, current_month) do
    {:ok, dt} = DateTime.from_unix(t, :millisecond)
    current_month == dt.month
  end

  defp add(%{"t" => _t, "v" => v}, acc), do: acc + v
end
