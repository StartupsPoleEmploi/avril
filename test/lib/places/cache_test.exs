defmodule Vae.Places.CacheTest do
  use ExUnit.Case

  alias Vae.Places.Cache

  @places_ets_table_name Application.get_env(:vae, :places_ets_table_name)

  test "nil postal code returns nil" do
    assert nil == Vae.Places.Cache.get_geoloc_from_postal_code(nil)
  end

  test "Non cached entry, retrieves geo_loc from places api and cache it" do
    expected_response = %{
      "_geoloc" => %{"lat" => 48.8916, "lng" => 2.31846},
      "_tags" => [
        "capital",
        "boundary/administrative",
        "city",
        "place/city",
        "country/fr",
        "source/pristine"
      ],
      "administrative" => ["Île-de-France"],
      "city" => ["Paris"],
      "country" => "France",
      "country_code" => "fr",
      "county" => ["Paris"],
      "is_city" => true,
      "locale_names" => ["Paris 17e Arrondissement"],
      "postcode" => ["75017"]
    }

    # Cache response
    assert expected_response === Cache.get_geoloc_from_postal_code("75017")

    # Cache storage
    entries = :ets.lookup(@places_ets_table_name, "75017")
    assert length(entries) === 1

    {_key, entry} = hd(entries)
    assert entry === expected_response
  end
end
