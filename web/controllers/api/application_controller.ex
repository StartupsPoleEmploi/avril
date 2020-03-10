defmodule Vae.Api.ApplicationController do
  use Vae.Web, :controller

  alias Vae.Application

  def list(conn, params) do
    current_user =
      conn.assigns[:current_user]
      |> Repo.preload(:applications)

    json(conn, %{
      status: :ok,
      data: to_view(current_user.applications)
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
end
