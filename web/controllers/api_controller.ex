defmodule Vae.ApiController do
  use Vae.Web, :controller
  plug Vae.Plugs.ApplicationAccess, [find_with_hash: :booklet_hash]

  def get_booklet(conn, %{"hash" => hash}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user])

    json(conn, %{
      status: :ok,
      identity: %{
        firstNames: [application.user.first_name],
        lastName: application.user.last_name,
        email: application.user.email,
        sex: application.user.gender
      }
    })
  end
end