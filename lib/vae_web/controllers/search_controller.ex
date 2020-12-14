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

  def public_search(conn, %{"query" => query, "index" => index}) when index in ["certification", "profession"] do
    res = from(e in Module.concat(Vae, index |> String.capitalize() |> String.to_atom()))
    |> or_where([e], ilike(field(e, :label), ^"%#{query}%"))
    |> Vae.Maybe.if(index == "certification", &or_where(&1, [e], ilike(field(e, :acronym), ^"%#{query}%")))
    |> limit(10)
    |> Vae.Repo.all()
    |> Enum.map(&(%{id: &1.id, label: &1.label}))

    json(conn, res)
  end
end
