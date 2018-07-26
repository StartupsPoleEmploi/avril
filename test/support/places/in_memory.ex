defmodule Vae.Places.Client.InMemory do
  @behaviour Vae.Places.Client

  def get_value(key) do
    case key do
      "foo" -> Enum.random(1..10)
      "bar" -> Enum.random(21..30)
      _ -> Enum.random(61..70)
    end
  end

  def current_month_stats({t, index}) when is_tuple(t) do
    {index, current_month_stats(t)}
  end

  def current_month_stats({k, _v}) do
    %{
      total_read_operations: [
        %{
          "t" => 1_528_243_200_000,
          "v" => get_value(k)
        },
        %{
          "t" => 1_528_243_200_001,
          "v" => get_value(k)
        }
      ]
    }
    |> Map.get(:total_read_operations)
    |> Enum.reduce(0, fn %{"t" => _t, "v" => v}, acc ->
      acc + v
    end)
  end

  def get_geoloc_from_postal_code(nil), do: nil

  def get_geoloc_from_postal_code(_value) do
    %{
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
  end

  def get_geoloc_from_address(_value), do: nil
end
