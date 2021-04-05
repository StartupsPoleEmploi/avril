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
    |> Enum.map(fn e -> Map.merge(e, %{name: module.name(struct(module, e)), index: index}) end)
    |> Enum.sort_by(&(-&1.sort))

    json(conn, res)
  end

  def build_query(Certification, query) do
    Certification.searchable_query()
    |> Vae.Search.FullTextSearch.run(query)
    |> select([e, v], %{id: e.id, label: e.label, acronym: e.acronym, slug: e.slug, sort: v.count})
  end

  def build_query(Profession, query) do
    from(e in Profession)
    |> Vae.Search.FullTextSearch.run(query)
    |> select([e, v], %{id: e.id, label: e.label, slug: e.slug, sort: e.priority, rank: v.rank})
  end

end
