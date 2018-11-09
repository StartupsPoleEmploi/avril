defmodule Vae.Places.Client.Algolia do
  require Logger

  @behaviour Vae.Places.Client

  @url_places "https://status.algolia.com/1/usage/total_read_operations/period/month/places"

  @algolia_places_query "https://places-dsn.algolia.net/1/places/query"
  @algolia_places_keys ~w(_geoloc country_code country administrative county city postcode locale_names _tags is_city)

  # ------------------------#
  #          Search        #
  # ------------------------#

  def get_geoloc_from_postal_code(postal_code), do: get(postal_code)

  def get_geoloc_from_address(address), do: get(address)

  defp get(query) do
    query
    |> get_first_hit()
    |> Map.take(@algolia_places_keys)
  end

  defp get_first_hit(query) do
    with {:ok, result} <- execute(query),
         hits <- Map.get(result, "hits"),
         first_hit <- List.first(hits) do
      first_hit
    else
      {_, error} -> Logger.warn(fn -> error end)
    end
  end

  defp execute(query) do
    with headers <- build_headers(),
         {:ok, body} <-
           Poison.encode(%{query: query, language: "fr", countries: ["fr"], hitsPerPage: 1}),
         {:ok, response} <- HTTPoison.post(@algolia_places_query, body, headers) do
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

  # TODO: extract to config module
  def get_config(:algolia_places_app_id), do: System.get_env("ALGOLIA_PLACES_APP_ID")
  def get_config(:algolia_places_api_key), do: System.get_env("ALGOLIA_PLACES_API_KEY")

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
