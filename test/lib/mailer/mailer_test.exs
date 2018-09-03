defmodule Vae.MailerTest do
  use Vae.DataCase

  alias Vae.Mailer
  alias Vae.Mailer.Email
  alias Vae.JobSeeker

  setup do
    Application.ensure_started(MailerWorker)
    Mailer.flush()
    :ok
  end

  test "test mailer extract" do
    Application.ensure_started(MailerWorker)

    expected_emails = [
      %Email{
        job_seeker: %JobSeeker{
          email: "foo@bar.com",
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
          email: "baz@qux.com",
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

    extracted_emails = Mailer.extract("path/to/file")

    assert length(extracted_emails) == 2

    assert ["foo@bar.com", "baz@qux.com"] ==
             Enum.map(extracted_emails, fn %Email{job_seeker: job_seeker} ->
               job_seeker.email
             end)
  end

  describe "Mailer Workflow" do
    test "no error on sending, the state is empty" do
      Application.ensure_started(MailerWorker)

      remaining_emails =
        Mailer.extract("path/to/file")
        |> Enum.map(fn email -> %{email | state: :success} end)
        |> Mailer.send()

      assert length(remaining_emails) == 0
      assert length(:ets.tab2list(:pending_emails)) == 0
    end

    test "error on sending, the state keeps emails on error" do
      Application.ensure_started(MailerWorker)

      remaining_emails =
        Mailer.extract("path/to/file")
        |> Enum.map(fn email -> %{email | state: :error} end)
        |> Mailer.send()

      assert length(remaining_emails) == 2
      assert length(:ets.tab2list(:pending_emails)) == 2
    end

    test "1 error on sending, the state keeps the email that is in error" do
      Application.ensure_started(MailerWorker)

      remaining_emails =
        Mailer.extract("path/to/file")
        |> List.update_at(0, fn email -> %{email | state: :error} end)
        |> List.update_at(1, fn email -> %{email | state: :success} end)
        |> Mailer.send()

      assert length(remaining_emails) == 1
      assert length(:ets.tab2list(:pending_emails)) == 1
    end
  end
end
