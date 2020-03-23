defmodule VaeWeb.Api.UserApplicationController do
  use VaeWeb, :controller

  alias Vae.Maybe
  alias Vae.Certification
  alias Vae.SearchDelegate
  alias VaeWeb.ViewHelpers

  def index(conn, _params) do
    current_user =
      conn.assigns[:current_user]
      |> Repo.preload(applications: [[delegate: :certifiers], :certification])

    json(conn, %{
      status: :ok,
      data: to_view(current_user.applications)
    })
  end

  def show(conn, %{"slug" => slug_param} = _params) do
    current_user =
      conn.assigns[:current_user]
      |> Repo.preload(applications: [[delegate: :certifiers], :certification])

    application =
      current_user.applications
      |> Enum.find(fn %{certification: %Certification{slug: slug}} -> slug == slug_param end)

    unless is_nil(application) do
      json(conn, %{
        status: :ok,
        data: to_dashboard_view(application)
      })
    else
      conn
      |> put_status(404)
      |> json(%{
        error: %{
          code: 404,
          message: "Not found"
        }
      })
    end
  end

  def delegates_search(conn, %{"slug" => slug_param} = _params) do
    current_user =
      conn.assigns[:current_user]
      |> Repo.preload(applications: [[delegate: :certifiers], :certification])

    application =
      current_user.applications
      |> Enum.find(fn %{certification: %Certification{slug: slug}} -> slug == slug_param end)

    %{"_geoloc" => geoloc, "postcode" => [postal_code]} =
      Vae.Places.get_geoloc_from_postal_code(current_user.postal_code)

    {_meta, delegates} =
      SearchDelegate.get_delegates(application.certification, geoloc, postal_code)

    json(
      conn,
      %{
        status: :ok,
        data: %{
          # application_id: id,
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
        # id: application.id,
        booklet_hash: application.booklet_hash,
        certification:
          application.certification
          |> Maybe.map(
            &%{
              slug: &1.slug,
              name: Certification.name(&1),
              level: ViewHelpers.level_info_by_level(&1.level)
            }
          ),
        delegate:
          application.delegate
          |> Maybe.map(
            &%{
              name: &1.name,
              certifier_name: &1.certifiers |> hd() |> Maybe.map(fn c -> c.name end),
              address: &1.address
            }
          ),
        created_at: application.inserted_at
      }
    end)
  end

  defp to_dashboard_view(application) do
    %{
      booklet_hash: application.booklet_hash,
      delegate:
        application.delegate
        |> Maybe.map(
          &%{
            name: &1.name,
            address: &1.address
          }
        ),
      certification:
        application.certification
        |> Maybe.map(
          &%{
            name: Certification.name(&1),
            level: ViewHelpers.level_info_by_level(&1.level)
          }
        ),
      receipts: []
    }
  end
end
