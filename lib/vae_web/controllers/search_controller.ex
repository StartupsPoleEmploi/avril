defmodule VaeWeb.SearchController do
  require Logger
  use VaeWeb, :controller

  def search(conn, _params) do
    conn
    |> put_flash(
      :warning,
      "Veuillez sélectionner une proposition dans les suggestions de recherche"
    )
    |> redirect(to: Routes.root_path(conn, :index))
  end
end
