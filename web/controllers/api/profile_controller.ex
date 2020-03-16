defmodule Vae.Api.ProfileController do
  use Vae.Web, :controller

  alias Vae.User

  def index(conn, params) do
    current_user = conn.assigns[:current_user]

    json(conn, %{
      status: :ok,
      data: to_view(current_user)
    })
  end

  def update(conn, params) do
    user =
      conn.assigns[:current_user]
      |> User.update_changeset(params)
      |> Repo.update!()

    json(conn, %{
      status: :ok,
      data: to_view(user)
    })
  end

  defp to_view(user) do
    %{
      gender: if(user.gender, do: user.gender |> String.downcase()),
      birthday: user.birthday,
      birth_place: %{
        city: user.birth_place
      },
      is_handicapped: false,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      mobile_phone: user.phone_number,
      full_address: %{
        city: user.city_label,
        country: user.country_label,
        postal_code: user.postal_code,
        street: User.address_street(user)
      }
    }
  end
end
