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
    %Vae.Application{
      booklet_hash: "plopplippluq",
      user: build({:user, date}),
      delegate: build(:delegate),
      certification: build(:certification),
      booklet_hash: "1234"
    }
  end

  def build({:user, date}) do
    %Vae.User{
      gender: "M",
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
      experiences: build(:experiences)
    }
  end

  def build(:experiences) do
    [
      %{
        label: "Chargé d'affaires Vidéosurveillance, alarme, gestion des accès ",
        company: "Ads Securite ",
        duration: 7,
        end_date: "2019-06-30T22:00:00Z",
        is_abroad: false,
        start_date: "2018-12-31T23:00:00Z",
        is_current_job: false
      },
      %{
        label: "President Sas",
        company: "Suissa Elec",
        duration: 28,
        end_date: "2017-12-31T23:00:00Z",
        is_abroad: false,
        start_date: "2015-09-30T22:00:00Z",
        is_current_job: false
      },
      %{
        label: "Ingénieur d'affaires",
        company: "Ecus Ondulique",
        duration: 21,
        end_date: "2014-08-31T22:00:00Z",
        is_abroad: false,
        start_date: "2012-12-31T23:00:00Z",
        is_current_job: false
      },
      %{
        label: "Entrepreneur et opérateur certifié",
        company: "Dan'diag",
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
