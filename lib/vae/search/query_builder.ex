defmodule Vae.Search.QueryBuilder do
  alias Vae.Certification

  def init(), do: %{filters: %{and: [], or: []}, query: [], aroundLatLng: []}

  def build_active_filter(query),
    do: add_and_filter(query, "is_active:true")

  def build_certification_filter(query, %Certification{id: id}),
    do: add_and_filter(query, "certifications:#{id}")

  def build_administrative_filter(query, administrative) when administrative not in [nil, ""],
    do: add_and_filter(query, "administrative:\"#{administrative}\"")

  def build_administrative_filter(query, _), do: query

  def build_certifier_filter(query, certifiers),
    do: Enum.reduce(certifiers, query, &add_or_filter(&2, "certifiers=#{&1.id}"))

  def build_certifier_ids_filter(query, certifiers),
    do: Enum.reduce(certifiers, query, &add_or_filter(&2, "certifier_id=#{&1.id}"))

  def build_geoloc(query, geo, radius \\ nil)
  def build_geoloc(query, %{lat: lat, lng: lng} = geo, radius) when nil not in [lat, lng],
    do: query |> add_aroundLatLng(geo) |> add_radius(radius || :all)

  def build_geoloc(query, _, _), do: query

  def build_academy_filter(query, nil),
    do: add_and_filter(query, "has_academy:false")

  def build_academy_filter(query, academy_id),
    do: add_and_filter(query, "academy_id:#{academy_id}")

  def build_query(query) do
    build_filters(query) ++ build_geo(query)
  end

  defp add_and_filter(query, filter), do: add_filter(query, {:and, filter})

  defp add_or_filter(query, filter), do: add_filter(query, {:or, filter})

  defp add_filter(query, {conjunction, filter}),
    do: update_in(query, [:filters, conjunction], &([filter | &1]))

  defp add_aroundLatLng(query, %{lat: lat, lng: lng}) do
    query
    |> update_in([:aroundLatLng], fn _ -> [lat, lng] end)
  end

  defp add_radius(query, radius) do
    query
    |> update_in([:aroundRadius], fn _ -> radius end)
  end

  defp build_filters(%{filters: %{or: [], and: []}} = query), do: query

  defp build_filters(%{filters: %{or: [], and: and_filter}}) when and_filter != [] do
    [filters: "#{Enum.join(and_filter, " AND ")}"]
  end

  defp build_filters(%{filters: %{or: or_filter, and: []}}) do
    [filters: "#{Enum.join(or_filter, " OR ")}"]
  end

  defp build_filters(%{filters: %{or: or_filter, and: and_filter}}) do
    [filters: "(#{Enum.join(or_filter, " OR ")}) AND #{Enum.join(and_filter, " AND ")}"]
  end

  defp build_geo(%{aroundLatLng: []}), do: []

  defp build_geo(%{aroundLatLng: lat_lng, aroundRadius: radius}) do
    [aroundLatLng: lat_lng, aroundRadius: radius]
  end

end