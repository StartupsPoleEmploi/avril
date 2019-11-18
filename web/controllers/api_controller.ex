defmodule Vae.ApiController do
  use Vae.Web, :controller

  alias Vae.{Certification, User}

  plug Vae.Plugs.ApplicationAccess, [find_with_hash: :booklet_hash]

  def get_booklet(conn, %{"hash" => hash}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user, :certification])
    user = application.user
    json(conn, %{
      status: :ok,
      data: Vae.Map.deep_merge(booklet_init_data(application), Map.from_struct(user.booklet_data))
    })
  end

  def set_booklet(conn, %{"hash" => hash} = params) do
    IO.inspect(params)
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

  defp booklet_init_data(application) do
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
          country: user.country_label,
          # "isDomTom" => false
        }
      }
    }
  end
end