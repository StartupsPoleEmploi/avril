defmodule Vae.Factory do
  alias Vae.Repo

  def build(:delegate) do
    %Vae.Delegate{
      name: unique_name("delegate"),
      person_name: unique_name("delegate_person_name"),
      process: build(:process)
    }
  end

  def build(:process) do
    %Vae.Process{name: unique_name("process")}
  end

  def build(:certifier_with_one_delegate) do
    %Vae.Certifier{
      name: unique_name("certifier"),
      delegates: [
        build(:delegate)
      ]
    }
  end

  def build(:certifier_with_delegates) do
    %Vae.Certifier{
      name: unique_name("certifier"),
      delegates: [
        build(:delegate),
        build(:delegate)
      ]
    }
  end

  def build(:application, date) do
    %Vae.UserApplication{
      user: build({:user, date}),
      certification: build(:certification),
      booklet_hash: "123456"
    }
  end

  def build({:user, date}) do
    %Vae.User{
      gender: "male",
      first_name: "John",
      last_name: "Doe",
      email: "john@doe.com",
      phone_number: "0102030405",
      postal_code: "75000",
      address1: "Street 1",
      address2: "Street 2",
      insee_code: "22",
      country_code: "FR",
      city_label: "Paris",
      country_label: "France",
      birthday: date,
      birth_place: "Dijon",
      proven_experiences: build(:proven_experiences)
    }
  end

  def build(:proven_experiences) do
    [
      %{
        label: "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès ",
        company_name: "Ads Securite ",
        duration: 7,
        end_date: "2019-06-30T22:00:00Z",
        is_abroad: false,
        start_date: "2018-12-31T23:00:00Z",
        is_current_job: false
      },
      %{
        label: "President Sas",
        company_name: "Suissa Elec",
        duration: 28,
        end_date: "2017-12-31T23:00:00Z",
        is_abroad: false,
        start_date: "2015-09-30T22:00:00Z",
        is_current_job: false
      },
      %{
        label: "Ingénieur d'affaires",
        company_name: "Ecus Ondulique",
        duration: 21,
        end_date: "2014-08-31T22:00:00Z",
        is_abroad: false,
        start_date: "2012-12-31T23:00:00Z",
        is_current_job: false
      },
      %{
        label: "Entrepreneur et opérateur certifié",
        company_name: "Dan'diag",
        duration: 33,
        end_date: "2012-08-31T22:00:00Z",
        is_abroad: false,
        start_date: "2009-12-31T23:00:00Z",
        is_current_job: false
      }
    ]
  end

  def build(:certification) do
    %Vae.Certification{
      label: "my certification",
      acronym: "BT",
      level: 1,
      rncp_id: "12345",
      description: "Top certification"
    }
  end

  def build(:application_with_booklet, date) do
    application = insert!(:application, date) |> Repo.preload(:resumes)

    cerfa = %{
      certifier_name: "Certifier",
      certification_name: "BT my certification",
      civility: %{
        nationality: %{
          country: "France",
          country_code: "FR"
        },
        gender: "m",
        birthday: date,
        birth_place: %{
          city: "Saint-Malo",
          country: nil,
          domTom: nil,
          lat: nil,
          lng: nil
        },
        first_name: "John",
        last_name: "Doe",
        usage_name: "Smith",
        email: "john@smith.com",
        home_phone: "0300000000",
        mobile_phone: "0600000000",
        full_address: %{
          city: "Saint-Malo",
          country: "France",
          lat: 45.3333,
          lng: 2.4323,
          postal_code: "35000",
          street: "23, Rue Jean Jaures"
        }
      },
      education: %{
        grade: 1,
        degree: 1,
        diplomas: [
          %{
            label: "CAP Boucher"
          },
          %{
            label: "BTS Boulanger"
          }
        ],
        courses: [
          %{
            label: "CAPES"
          },
          %{
            label: "CACES"
          }
        ]
      },
      experiences: [
        %{
          uuid: "1",
          title: "Responsable Boucherie",
          company_name: "Butcher Market",
          full_address: %{
            city: "Saint-Malo",
            country: "FR",
            domTom: nil,
            lat: 32.1111,
            lng: 2.1111,
            postal_code: "35000",
            street: "Centre commercial Binard"
          },
          job_industry: "H",
          employment_type: 1,
          periods: [
            %{
              start_date: ~D[2019-11-30],
              end_date: ~D[2018-11-30],
              week_hours_duration: 35
            }
          ],
          skills: [
            %{
              label: "Découpe de charcuterie"
            },
            %{
              label: "Affutage"
            },
            %{
              label: "Découpe de poulet"
            },
            %{
              label: "Rotisserie"
            }
          ]
        },
        %{
          uuid: "2",
          title: "Responsable Patisserie",
          company_name: "Baker Market",
          full_address: %{
            city: "Saint-Malo",
            country: "FR",
            domTom: nil,
            lat: 32.1111,
            lng: 2.1111,
            postal_code: "35000",
            street: "Centre commercial Binard"
          },
          job_industry: "H",
          employment_type: 4,
          periods: [
            %{
              start_date: ~D[2018-11-29],
              end_date: ~D[2017-11-30],
              week_hours_duration: 35
            }
          ],
          skills: [
            %{
              label: "Glacage"
            },
            %{
              label: "Pate brisée"
            }
          ]
        }
      ]
    }

    application
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:booklet_1, cerfa)
    |> Repo.update!()
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    build(factory_name, attributes)
    |> Repo.insert!()
  end

  defp unique_name(prefix) do
    prefix <> Integer.to_string(System.unique_integer())
  end
end
