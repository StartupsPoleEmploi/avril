defmodule Vae.Api.ApplicationController do
  use Vae.Web, :controller

  alias Vae.{Application, User}

  def list(conn, params) do
    current_user =
      conn.assigns[:current_user]
      |> Repo.preload(:applications)

    json(conn, %{
      status: :ok,
      data: to_view(current_user.applications)
    })
  end

  def dashboard(conn, %{"id" => id} = params) do
    user = conn.assigns[:current_user]

    application = Vae.Application.from_application_id_and_user_id(id, user.id)

    json(conn, %{
      status: :ok,
      data: to_dashboard_view(application, user)
    })
  end

  defp to_view(applications) do
    applications
    |> Enum.map(fn application ->
      %{
        id: application.id,
        delegate_name: Application.delegate_name(application),
        certification_name: Application.certification_name(application),
        created_at: application.inserted_at
      }
    end)
  end

  defp to_dashboard_view(application, user) do
    %{
      civility: %{
        gender: if(user.gender, do: user.gender |> String.downcase()),
        first_name: user.first_name,
        last_name: user.last_name,
        full_address: %{
          city: user.city_label,
          country: user.country_label,
          postal_code: user.postal_code,
          street: User.address_street(user)
        }
      },
      booklet_hash: application.booklet_hash,
      delegates: %{
        name: application.delegate.name,
        full_address: application.delegate.address
      },
      certification: %{
        label: application.certification.label,
        level: application.certification.level
      },
      receipts: []
    }
  end
end
