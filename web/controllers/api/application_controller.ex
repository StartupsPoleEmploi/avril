defmodule Vae.Api.ApplicationController do
  use Vae.Web, :controller

  alias Vae.SearchDelegate
  alias Vae.{Application, Certification, User}

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

  def delegates_search(conn, %{"id" => id} = params) do
    user = conn.assigns[:current_user]

    %{"_geoloc" => geoloc, "postcode" => [postal_code]} =
      Vae.Places.get_geoloc_from_postal_code(user.postal_code)

    application = Vae.Application.from_application_id_and_user_id(id, user.id)

    certification = Repo.get(Certification, application.certification_id)

    {_meta, delegates} = SearchDelegate.get_delegates(certification, geoloc, postal_code)

    json(
      conn,
      %{
        status: :ok,
        data: %{
          application_id: id,
          delegates:
            Enum.map(delegates, fn delegate ->
              %{
                id: delegate.id,
                name: delegate.name,
                address: delegate.address
              }
            end)
        }
      }
    )
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
      delegate: %{
        name: application.delegate.name,
        full_address: application.delegate.address
      },
      certification: %{
        id: application.certification.id,
        label: application.certification.label,
        level: application.certification.level
      },
      receipts: []
    }
  end
end
