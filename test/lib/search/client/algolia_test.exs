defmodule Vae.Search.Client.AlgoliaTest do
  use ExUnit.Case

  alias Vae.Search.Client.Algolia
  alias Vae.Certifier

  test "build is_active filter" do
    query = %{
      filters: %{
        and: [
          "is_active:true"
        ],
        or: []
      },
      query: [],
      aroundLatLng: []
    }

    assert query == Algolia.init() |> Algolia.build_active_filter()
  end

  test "build certifiers filter" do
    query = %{
      filters: %{
        and: [],
        or: ["certifiers=1", "certifiers=2", "certifiers=3"]
      },
      query: [],
      aroundLatLng: []
    }

    certifiers = [
      %Certifier{id: 1},
      %Certifier{id: 2},
      %Certifier{id: 3}
    ]

    assert query[:filters][:or] --
             (Algolia.init()
              |> Algolia.build_certifier_filter(certifiers)
              |> get_in([:filters, :or])) == []
  end

  test "build geoloc" do
    query = %{
      filters: %{
        and: [],
        or: []
      },
      query: [],
      aroundLatLng: ["48.866667", "2.333333"]
    }

    assert query ==
             Algolia.init() |> Algolia.build_geoloc(%{"lat" => "48.866667", "lng" => "2.333333"})
  end

  test "full filter built" do
    query = %{
      filters: %{
        and: [
          "is_active:true"
        ],
        or: ["certifiers=1", "certifiers=2", "certifiers=3"]
      },
      query: [],
      aroundLatLng: ["48.866667", "2.333333"]
    }

    certifiers = [
      %Certifier{id: 1},
      %Certifier{id: 2},
      %Certifier{id: 3}
    ]

    built_query =
      Algolia.init()
      |> Algolia.build_active_filter()
      |> Algolia.build_certifier_filter(certifiers)
      |> Algolia.build_geoloc(%{"lat" => "48.866667", "lng" => "2.333333"})

    assert get_in(query, [:filters, :or]) -- get_in(built_query, [:filters, :or]) == []
    assert get_in(query, [:filters, :and]) == get_in(built_query, [:filters, :and])
    assert get_in(query, [:aroundLatLng]) == get_in(built_query, [:aroundLatLng])
  end

  test "build query" do
    certifiers = [
      %Certifier{id: 1},
      %Certifier{id: 2},
      %Certifier{id: 3}
    ]

    built_query =
      Algolia.init()
      |> Algolia.build_active_filter()
      |> Algolia.build_certifier_filter(certifiers)
      |> Algolia.build_geoloc(%{"lat" => "48.866667", "lng" => "2.333333"})

    [
      aroundLatLng: ["48.866667", "2.333333"],
      filters: "(certifiers=1 OR certifiers=2 OR certifiers=3) AND (is_active=true)"
    ] == Algolia.build_query(built_query)
  end
end
