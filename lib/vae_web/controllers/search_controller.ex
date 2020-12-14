defmodule VaeWeb.SearchController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{Certification, Profession}

  def search(conn, _params) do
    conn
    |> put_flash(
      :warning,
      "Veuillez sélectionner une proposition dans les suggestions de recherche"
    )
    |> redirect(to: Routes.root_path(conn, :index))
  end

  def public_search(conn, %{"query" => query, "index" => index}) when index in ["certification", "profession"] do
    module = Module.concat(Vae, index |> String.capitalize() |> String.to_atom())

    res = build_query(module, query)
    |> limit(5)
    |> Vae.Repo.all()
    |> Enum.map(fn %module{id: id, slug: slug} = e -> %{id: id, name: module.name(e), slug: slug, index: index} end)

    json(conn, res)
  end

  def build_query(Certification, query) do
    from(e in Certification, where: e.is_active)
    |> where([e], ilike(field(e, :label), ^"%#{query}%"))
    # |> or_where([e], ilike(field(e, :acronym), ^"%#{query}%"))
    |> Certification.sort_by_popularity()
  end

  def build_query(Profession, query) do
    from(e in Profession)
    |> or_where([e], ilike(field(e, :label), ^"%#{query}%"))
    |> order_by([e], desc: e.priority)
  end

end
