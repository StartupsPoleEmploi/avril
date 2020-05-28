defmodule Vae.ExFactory do
  use ExMachina.Ecto, repo: Vae.Repo

  alias Vae.String
  alias Vae.{Certification, Certifier, Delegate, User, UserApplication}

  def user_factory() do
    %User{
      first_name: "Jane",
      last_name: "Doe",
      postal_code: "35000",
      email: "foo@bar.com"
    }
  end

  def user_with_identity_factory() do
    %User{
      first_name: "Jane",
      last_name: "Doe",
      postal_code: "35000",
      email: "foo@bar.com",
      identity: build(:identity)
    }
  end

  def identity_factory() do
    %Vae.Identity{
      gender: "M",
      birthday: ~D[1981-06-24],
      first_name: "John",
      last_name: "Smith",
      usage_name: "Doe",
      email: "john@smith.com",
      home_phone: "0100000000",
      mobile_phone: "0600000000",
      is_handicapped: false,
      birth_place: %{
        city: "Paris",
        country: "France"
      },
      full_address: %{
        city: "Toulouse",
        postal_code: "31000",
        country: "France",
        street: "1, rue de la Bergerie",
        lat: "43.600000",
        lng: "1.433333"
      },
      current_situation: %{
        status: "job_seeker",
        employment_type: "employee",
        register_to_pole_emploi: true,
        register_to_pole_emploi_since: ~D[2019-02-01],
        compensation_type: "pole-emploi"
      },
      nationality: %{
        country: "France",
        country_code: "FR"
      }
    }
  end

  def set_password(user, password) do
    user
    |> User.changeset(%{"password" => password})
    |> Ecto.Changeset.apply_changes()
  end

  def delegate_factory() do
    %Delegate{
      name: "Delegate 1",
      person_name: "Marc Aurele",
      address: "3001  Meadowbrook Mall Road, 90025, West Los Angeles",
      city: "West Los Angeles",
      telephone: "0000000000",
      email: "marcorl@gladia.tor",
      certifiers: [build(:certifier)]
    }
  end

  def certification_factory() do
    label = generate_certification_label()
    acronym = generate_certification_acronym()

    %Certification{
      label: label,
      acronym: acronym,
      level: "1",
      description:
        "My name is Maximus Decimus Meridius, commander of the Armies of the North, General of the Felix Legions and loyal servant to the true emperor, Marcus Aurelius. Father to a murdered son, husband to a murdered wife. And I will have my vengeance, in this life or the next.",
      slug: generate_certification_slug([label, acronym])
    }
  end

  def certifier_factory() do
    %Certifier{
      name: generate_certifier_name()
    }
  end

  def application_without_delegate_factory() do
    %UserApplication{
      booklet_hash: :crypto.strong_rand_bytes(64) |> Base.url_encode64() |> binary_part(0, 64),
      certification: build(:certification)
    }
  end

  def application_factory() do
    %UserApplication{
      booklet_hash: :crypto.strong_rand_bytes(64) |> Base.url_encode64() |> binary_part(0, 64),
      delegate: build(:delegate),
      certification: build(:certification)
    }
  end

  def application_with_booklet_factory() do
    %UserApplication{
      booklet_hash: :crypto.strong_rand_bytes(64) |> Base.url_encode64() |> binary_part(0, 64),
      delegate: build(:delegate),
      certification: build(:certification),
      booklet_1: build(:booklet_1)
    }
  end

  def booklet_1_factory() do
    %Vae.Booklet.Cerfa{
      civility: build(:identity)
    }
  end

  defp generate_certifier_name(), do: generate_random_string(12)

  defp generate_certification_label(), do: generate_random_string(12)

  defp generate_certification_acronym(), do: generate_random_string(2)

  defp generate_random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode64() |> binary_part(0, length)
  end

  defp generate_certification_slug(params) do
    params
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> String.parameterize()
  end
end
