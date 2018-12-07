defmodule Vae.Search.Client.Algolia do
  require Logger

  @behaviour Vae.Search.Client

  def get_delegates(certifiers, geoloc) do
    query =
      init()
      |> build_certifier_filter(certifiers)
      |> build_geoloc(geoloc)

    execute(:delegate, query)
  end

  defp init(), do: []

  defp build_certifier_filter(query, certifiers) do
    filter =
      certifiers
      |> Enum.map(&"certifiers=#{&1.id}")
      |> Enum.join(" OR ")

    [{:filters, filter} | query]
  end

  defp build_geoloc(query, %{"lat" => lat, "lng" => lng}) when nil not in [lat, lng] do
    [{:aroundLatLng, [lat, lng]} | query]
  end

  defp build_geoloc(query, _), do: query

  defp execute(:delegate, query) do
    Algolia.search("delegate", "", query)
    |> case do
      {:ok, response} ->
        {:ok,
         response
         |> Map.get("hits")
         |> Enum.map(fn item ->
           Enum.reduce(item, %{}, fn {key, val}, acc ->
             Map.put(acc, String.to_atom(key), val)
           end)
         end)}

      {:error, code, msg} ->
        {:error, "#{code}: #{msg}"}

      {:error, msg} ->
        {:error, msg}
    end
  end
end
