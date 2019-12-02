defmodule Vae.ApiController do
  use Vae.Web, :controller

  alias Vae.{Application, Certification, User}

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
      data: data
    })
  end

  def set_booklet(conn, %{"hash" => hash} = params) do
    conn.assigns[:current_application]
    |> Application.save_booklet(%{"booklet_1" => params})
    |> case do
      {:ok, _application} ->
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

  def from_application(application) do
    user = application.user

    %Vae.Booklet.Cerfa{
      certification_name: Certification.name(application.certification),
      civility: %Vae.Booklet.Civility{
        gender: user.gender,
        birthday: user.birthday,
        birth_place: user.birth_place,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        mobile_phone: user.phone_number,
        full_address: User.address_inline(user),
        street_address: User.address_street(user),
        postal_code: user.postal_code,
        city: User.address_city(user),
        country: user.country_label
      },
      experiences: map_experiences(user.proven_experiences)
    }
  end

  def map_experiences([]), do: []

  def map_experiences(experiences),
    do: Enum.map(experiences, &map_experience/1)

  def map_experience(experience) do
    %Vae.Booklet.Experience{
      title: experience.label,
      company_name: experience.company_name,
      full_address: nil,
      employment_type: experience.contract_type,
      start_date: experience.start_date,
      end_date: experience.end_date,
      week_hours_duration: 35
    }
  end
end
