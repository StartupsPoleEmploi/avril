defmodule Vae.Mailer.FileExtractor.Mock do
  @behaviour Vae.Mailer.FileExtractor

  alias Vae.Mailer.Email
  alias Vae.JobSeeker

  def extract(_path, list) do
    [
      %Email{
        job_seeker: %JobSeeker{
          geolocation: %{
            "_geoloc" => %{"lat" => 45.7578, "lng" => 4.80124},
            "_tags" => [
              "boundary/administrative",
              "city",
              "place/city",
              "country/fr",
              "source/pristine"
            ],
            "administrative" => ["Auvergne-Rhône-Alpes"],
            "city" => ["Lyon"],
            "country" => "France",
            "country_code" => "fr",
            "county" => ["Rhône"],
            "is_city" => true,
            "locale_names" => ["Lyon 5e Arrondissement"],
            "postcode" => ["69005"]
          }
        }
      },
      %Email{
        job_seeker: %JobSeeker{
          geolocation: %{
            "_geoloc" => %{"lat" => 45.7578, "lng" => 4.80124},
            "_tags" => [
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
        }
      },
      %Email{
        job_seeker: %JobSeeker{
          geolocation: %{
            "_geoloc" => %{"lat" => 45.7578, "lng" => 4.80124},
            "_tags" => [
              "boundary/administrative",
              "city",
              "place/city",
              "country/fr",
              "source/pristine"
            ],
            "administrative" => ["Bourgogne-Franche-Comté"],
            "city" => ["Beaune"],
            "country" => "France",
            "country_code" => "fr",
            "county" => ["Côte-d'Or"],
            "is_city" => true,
            "locale_names" => ["Beaune"],
            "postcode" => ["21200"]
          }
        }
      }
    ]
  end
end
