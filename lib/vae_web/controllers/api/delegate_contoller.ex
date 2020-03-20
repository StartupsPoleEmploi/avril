defmodule VaeWeb.Api.DelegateController do
  use VaeWeb, :controller

  alias Vae.SearchDelegate
  alias Vae.Certification

  def search(conn, %{"certification_id" => certification_id} = _params) do
    user = conn.assigns[:current_user]

    %{"_geoloc" => geoloc, "postcode" => [postal_code]} =
      Vae.Places.get_geoloc_from_postal_code(user.postal_code)

    certification = Repo.get(Certification, certification_id)

    {_meta, delegates} = SearchDelegate.get_delegates(certification, geoloc, postal_code)

    json(
      conn,
      %{
        status: :ok,
        data: to_view(delegates)
      }
    )
  end

  defp to_view(delegates) do
    Enum.map(delegates, fn delegate ->
      %{
        id: delegate.id,
        name: delegate.name,
        address: delegate.address
      }
    end)
  end
end
