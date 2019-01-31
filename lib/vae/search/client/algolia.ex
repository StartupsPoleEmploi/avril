defmodule Vae.Search.Client.Algolia do
  require Logger

  @behaviour Vae.Search.Client

  def get_delegates(certifiers, geoloc) do
    query =
      init()
      |> build_active_filter()
      |> build_certifier_filter(certifiers)
      |> build_geoloc(geoloc)
      |> build_query()

    execute(:delegate, query)
  end

  def init(), do: %{filters: %{and: [], or: []}, query: [], aroundLatLng: []}

  def build_active_filter(query) do
    add_and_filter(query, "is_active:true")
  end

  def build_certifier_filter(query, certifiers) do
    Enum.reduce(certifiers, query, fn certifier, acc ->
      add_or_filter(acc, "certifiers=#{certifier.id}")
    end)
  end

  def build_geoloc(query, %{"lat" => lat, "lng" => lng} = geo) when nil not in [lat, lng] do
    add_aroundLatLng(query, geo)
  end

  def build_geoloc(query, _), do: query

  def build_query(query) do
    build_filters(query) ++ build_geo(query)
  end

  defp add_and_filter(query, filter) do
    add_filter(query, {:and, filter})
  end

  defp add_or_filter(query, filter) do
    add_filter(query, {:or, filter})
  end

  defp add_filter(query, {conjunction, filter}) do
    update_in(query, [:filters, conjunction], fn existing_filter ->
      [filter | existing_filter]
    end)
  end

  defp add_aroundLatLng(query, %{"lat" => lat, "lng" => lng}) do
    update_in(query, [:aroundLatLng], fn _ -> [lat, lng] end)
  end

  defp build_filters(%{filters: []} = query), do: query

  defp build_filters(%{filters: %{or: or_filter, and: and_filter}}) do
    [filters: "(#{Enum.join(or_filter, " OR ")}) AND #{Enum.join(and_filter, " AND ")}"]
  end

  defp build_geo(%{aroundLatLng: []} = query), do: []

  defp build_geo(%{aroundLatLng: lat_lng}) do
    [aroundLatLng: lat_lng]
  end

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

  def get_index_name(model) do
    model
    |> to_string()
    |> String.split(".")
    |> List.last()
    |> String.downcase()
  end
end
