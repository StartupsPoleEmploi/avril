defmodule Vae.ExFactory do
  use ExMachina.Ecto, repo: Vae.Repo

  alias Vae.String
  alias Vae.{Certification, Certifier, Delegate, ProvenExperience, User, UserApplication}

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

  def user_with_proven_experiences_factory() do
    struct!(
      user_with_identity_factory(),
      proven_experiences: [
        build(:proven_experience),
        build(
          :proven_experience,
          %{
            start_date: ~D[2017-10-23],
            end_date: ~D[2017-10-25],
            work_duration: "24",
            duration: "3"
          }
        ),
        build(
          :proven_experience,
          %{
            label: "Réalisateur",
            company_name: "PE Production",
            start_date: ~D[2017-11-01],
            end_date: ~D[2017-11-25],
            work_duration: "89",
            duration: "24"
          }
        )
      ]
    )
  end

  def proven_experience_factory() do
    %{
      label: "Assistant réalisateur adjoint",
      duration: "17",
      end_date: ~D[2017-09-20],
      is_manager: false,
      start_date: ~D[2017-09-04],
      company_ape: "5911B",
      company_uid: "1000",
      company_name: "Avril Production",
      contract_type: "CDD",
      work_duration: "88",
      company_category: "Employeur du Spectacle",
      company_state_owned: false
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
    struct!(
      application_factory(),
      booklet_1: build(:booklet_1)
    )
  end

  def application_with_complete_booklet_factory() do
    struct!(
      application_factory(),
      booklet_1: build(:complete_booklet_1)
    )
  end

  def booklet_1_factory() do
    %Vae.Booklet.Cerfa{
      civility: build(:identity)
    }
  end

  def complete_booklet_1_factory() do
    struct!(
      booklet_1_factory(),
      certification_name: "Init Certificiation Name",
      certifier_name: "Init Certifier Name",
      education: education(),
      experiences: experiences()
    )
  end

  defp education() do
    %Vae.Booklet.Education{
      grade: 1,
      degree: 1,
      diplomas: diplomas(),
      courses: courses()
    }
  end

  defp diplomas() do
    [
      %{label: "Init diploma 1"},
      %{label: "Init diploma 2"}
    ]
  end

  defp courses() do
    [
      %{label: "Init course 1"},
      %{label: "Init course 2"},
      %{label: "Init course 3"}
    ]
  end

  defp experiences() do
    [
      %Vae.Booklet.Experience{
        uuid: "1",
        title: "init title XP1",
        company_name: "init company name XP 1",
        job_industry: "init job_industry XP 1",
        employment_type: 1,
        skills: skills(),
        periods: [period(~D[2019-01-01]), period(~D[2019-03-01])],
        full_address: full_address()
      },
      %Vae.Booklet.Experience{
        uuid: "2",
        title: "init title XP2",
        company_name: "init company name XP 2",
        job_industry: "init job_industry XP 2",
        employment_type: 2,
        skills: skills(),
        periods: [period(~D[2020-01-01])],
        full_address: full_address()
      }
    ]
  end

  defp skills() do
    [
      %Vae.Booklet.Experience.Skill{label: "init skill 1"},
      %Vae.Booklet.Experience.Skill{label: "init skill 2"},
      %Vae.Booklet.Experience.Skill{label: "init skill 3"}
    ]
  end

  defp period(start_date) do
    %{
      start_date: start_date,
      end_date: Date.add(start_date, 30),
      week_hours_duration: 35,
      total_hours: 174
    }
  end

  defp full_address() do
    %Vae.Booklet.Address{
      city: "Init city",
      county: "Init county",
      country: "Init country",
      lat: 2.33445,
      lng: 4.66990,
      street: "Init Street address",
      postal_code: "Init Postal Code"
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
