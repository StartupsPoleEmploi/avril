defmodule Vae.Search.Client.InMemory do
  @behaviour Vae.Search.Client

  @delegates [
    %{
      _geoloc: %{"lat" => 48.6537, "lng" => -1.9932},
      _highlightResult: %{
        "_geoloc" => %{
          "lat" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "48.6537"
          },
          "lng" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "-1.9932"
          }
        },
        "address" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "75 Boulevard de la Fontaine - 35400 Saint-Malo"
        },
        "administrative" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Bretagne"
        },
        "certifiers" => [
          %{"matchLevel" => "none", "matchedWords" => [], "value" => "4"}
        ],
        "city" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Saint-Malo"
        },
        "email" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "john@doe.fr"
        },
        "geolocation" => %{
          "_geoloc" => %{
            "lat" => %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "48.6537"
            },
            "lng" => %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "-1.9932"
            }
          },
          "_tags" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "address"},
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "highway"},
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "highway/residential"
            },
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "country/fr"
            },
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "source/pristine"
            }
          ],
          "administrative" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "Bretagne"}
          ],
          "city" => [
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "Saint-Malo"
            }
          ],
          "country" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "France"
          },
          "country_code" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "fr"
          },
          "county" => [
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "Ille-et-Vilaine"
            }
          ],
          "locale_names" => [
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "75 Boulevard de la fontaine"
            }
          ],
          "postcode" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "35400"}
          ]
        },
        "id" => %{"matchLevel" => "none", "matchedWords" => [], "value" => "72"},
        "inserted_at" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "2018-03-30T09:41:25.268541"
        },
        "name" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Delegate Saint-Malo"
        },
        "person_name" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "John Doe"
        },
        "process_id" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "34"
        },
        "telephone" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "00.00.00.55.26"
        },
        "updated_at" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "2018-05-16T14:41:01.994568"
        }
      },
      address: "75 Boulevard de la Fontaine - 35400 Saint-Malo",
      administrative: "Bretagne",
      certifiers: [4],
      city: "Saint-Malo",
      email: "john@doe.fr",
      geolocation: %{
        "_geoloc" => %{"lat" => 48.6537, "lng" => -1.9932},
        "_tags" => ["address", "highway", "highway/residential", "country/fr", "source/pristine"],
        "administrative" => ["Bretagne"],
        "city" => ["Saint-Malo"],
        "country" => "France",
        "country_code" => "fr",
        "county" => ["Ille-et-Vilaine"],
        "is_city" => false,
        "locale_names" => ["75 Boulevard de la Fontaine"],
        "postcode" => ["35400"]
      },
      id: 72,
      inserted_at: "2018-03-30T09:41:25.268541",
      is_active: true,
      name: "Delegate Saint-Malo",
      objectID: "72",
      person_name: "John Doe",
      process_id: 34,
      telephone: "00.00.00.55.26",
      updated_at: "2018-05-16T14:41:01.994568",
      website: nil
    },
    %{
      _geoloc: %{"lat" => 48.0987, "lng" => -1.63764},
      _highlightResult: %{
        "_geoloc" => %{
          "lat" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "48.0987"
          },
          "lng" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "-1.63764"
          }
        },
        "address" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "6 Avenue de Jouvence - 35000 Rennes"
        },
        "administrative" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Bretagne"
        },
        "certifiers" => [
          %{"matchLevel" => "none", "matchedWords" => [], "value" => "4"}
        ],
        "city" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Rennes"
        },
        "email" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "jane@smith.fr"
        },
        "geolocation" => %{
          "_geoloc" => %{
            "lat" => %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "48.0987"
            },
            "lng" => %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "-1.63764"
            }
          },
          "_tags" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "address"},
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "highway"},
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "highway/residential"
            },
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "country/fr"
            },
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "source/pristine"
            }
          ],
          "administrative" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "Bretagne"}
          ],
          "city" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "Rennes"}
          ],
          "country" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "France"
          },
          "country_code" => %{
            "matchLevel" => "none",
            "matchedWords" => [],
            "value" => "fr"
          },
          "county" => [
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "Ille-et-Vilaine"
            }
          ],
          "locale_names" => [
            %{
              "matchLevel" => "none",
              "matchedWords" => [],
              "value" => "6 Avenue de Jouvence"
            }
          ],
          "postcode" => [
            %{"matchLevel" => "none", "matchedWords" => [], "value" => "35000"}
          ]
        },
        "id" => %{"matchLevel" => "none", "matchedWords" => [], "value" => "71"},
        "inserted_at" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "2018-03-30T09:40:11.924959"
        },
        "name" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Delegate Rennes"
        },
        "person_name" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "Jane Smith"
        },
        "process_id" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "34"
        },
        "telephone" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "00.00.00.95.52"
        },
        "updated_at" => %{
          "matchLevel" => "none",
          "matchedWords" => [],
          "value" => "2018-05-16T14:41:01.893557"
        }
      },
      address: "6 Avenue de Jouvence - 35000 Rennes",
      administrative: "Bretagne",
      certifiers: [4],
      city: "Rennes",
      email: "jane@smith.fr",
      geolocation: %{
        "_geoloc" => %{"lat" => 48.0987, "lng" => -1.63764},
        "_tags" => ["address", "highway", "highway/residential", "country/fr", "source/pristine"],
        "administrative" => ["Bretagne"],
        "city" => ["Rennes"],
        "country" => "France",
        "country_code" => "fr",
        "county" => ["Ille-et-Vilaine"],
        "is_city" => false,
        "locale_names" => ["6 Avenue de Jouvence"],
        "postcode" => ["35000"]
      },
      id: 71,
      inserted_at: "2018-03-30T09:40:11.924959",
      is_active: true,
      name: "Delegate Rennes",
      objectID: "71",
      person_name: "Jane Smith",
      process_id: 34,
      telephone: "00.00.00.95.52",
      updated_at: "2018-05-16T14:41:01.893557",
      website: nil
    }
  ]

  def get_delegates(_certifiers, _geoloc) do
    {:ok, @delegates}
  end

  def get_index_name(model), do: model |> to_string()
end
