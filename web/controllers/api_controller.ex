defmodule Vae.ApiController do
  use Vae.Web, :controller

  alias Vae.{Certification, User}

  plug Vae.Plugs.ApplicationAccess, find_with_hash: :booklet_hash

  def get_booklet(conn, %{"hash" => hash}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user, :certification])

    data =
      case application.booklet_1 do
        nil -> from_application(application)
        booklet -> booklet
      end

    json(conn, %{
      status: :ok,
      data: data |> to_view()
    })
  end

  def set_booklet(conn, %{"hash" => hash} = params) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user])

    user = application.user

    case User.changeset(user, %{booklet_data: params}) |> Repo.update() do
      {:ok, user} ->
        json(conn, %{
          status: :ok
        })

      {:error, error} ->
        json(conn, %{
          status: :error,
          error: error
        })
    end
  end

  def to_view(data) do
    %{
      certificationLabel: data.certification_name,
      identity: %{
        firstNames: [data.civility.first_name],
        lastName: data.civility.last_name,
        email: data.civility.email,
        sex: data.civility.gender,
        cellPhoneNumber: data.civility.mobile_number,
        birth: %{
          date: data.civility.birthday,
          # county: null,
          # country: 'FR',
          city: data.civility.birth_place
        },
        address: %{
          street: data.civility.street_address,
          # streetType: null,
          # streetName: null,
          # streetNumber: null,
          city: data.civility.city,
          postalCode: data.civility.postal_code,
          country: data.civility.country
          # "isDomTom" => false
        }
      }
    }
  end

  def from_application(application) do
    user = application.user

    %{
      certification_name: Certification.name(application.certification),
      civility: %{
        gender: user.gender,
        birthday: user.birthday,
        birth_place: user.birth_place,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        mobile_number: user.phone_number,
        street_address: User.address_street(user),
        postal_code: user.postal_code,
        city: user.city_label,
        country: user.country_label
      },
      education: %{},
      experiences: []
    }
  end

  def booklet_init_data(application) do
    user = application.user

    %{
      certificationLabel: Certification.name(application.certification),
      identity: %{
        firstNames: [user.first_name],
        lastName: user.last_name,
        email: user.email,
        sex: user.gender,
        cellPhoneNumber: user.phone_number,
        birth: %{
          date: user.birthday,
          # county: null,
          # country: 'FR',
          city: user.birth_place
        },
        address: %{
          street: User.address_street(user),
          # streetType: null,
          # streetName: null,
          # streetNumber: null,
          city: user.city_label,
          postalCode: user.postal_code,
          country: user.country_label
          # "isDomTom" => false
        }
      }
    }
  end
end
