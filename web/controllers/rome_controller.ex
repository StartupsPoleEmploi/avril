defmodule Vae.RomeController do
  require Logger

  use Vae.Web, :controller

  alias Vae.{Rome}

  def index(conn, params) do
    render(conn, "index.html",
      romes: Rome.categories()
    )
  end

  def show(conn, %{"id" => id} = _params) do
    [code, slug] = String.split(id, "-", parts: 2)
    rome = Repo.get_by(Rome, code: code)

    cond do
      rome.slug != slug ->
        redirect(conn, to: Routes.rome_path(conn, :show, rome))
      Rome.is_category?(rome) ->
        render(conn, "index.html",
          rome: rome,
          romes: Rome.subcategories(rome)
        )
      Rome.is_subcategory?(rome) ->
        render(conn, "index.html",
          rome: rome,
          romes: Rome.romes(rome),
          category: Rome.category(rome)
        )
      true ->
        rome = Repo.preload(rome, [:professions, :certifications])
        render(conn, "show.html",
          rome: rome,
          subcategory: Rome.subcategory(rome),
          category: Rome.category(rome)
        )
    end

  end
end
