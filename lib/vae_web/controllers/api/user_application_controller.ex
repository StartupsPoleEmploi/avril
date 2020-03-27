defmodule VaeWeb.Api.UserApplicationController do
  use VaeWeb, :controller

  alias Vae.Maybe
  alias Vae.Certification
  alias Vae.SearchDelegate
  alias VaeWeb.ViewHelpers
  alias Vae.UserApplication, as: Application

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

  def update(conn, %{"slug" => slug_param} = _params) do
    IO.inspect(_params)
    delegate_id = nil
    with(
      current_user when not is_nil(current_user) <- conn.assigns[:current_user]
      |> Repo.preload(:applications),
      application when not is_nil(application) <- current_user.applications
        |> Enum.find(fn %{certification: %Certification{slug: slug}} -> slug == slug_param end),
      delegate when not is_nil(delegate) <- Repo.get(Delegate, delegate_id),
      {:ok, application} = Application.set_delegate(application, delegate)
    ) do
      redirect(conn, to: Routes.api_v1_user_application_path(conn, :show, application))
    else
      error ->
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

  def delegates_search(conn, %{"slug" => slug_param, "lat" => lat, "lng" => lng} = params) do
    current_user =
      conn.assigns[:current_user]
      |> Repo.preload(applications: [[delegate: :certifiers], :certification])

    application =
      current_user.applications
      |> Enum.find(fn %{certification: %Certification{slug: slug}} -> slug == slug_param end)

    {_meta, delegates} =
      SearchDelegate.get_delegates(application.certification, %{
        lat: lat,
        lng: lng
      }, params["postal_code"])

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
