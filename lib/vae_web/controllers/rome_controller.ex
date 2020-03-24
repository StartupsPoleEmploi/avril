defmodule VaeWeb.RomeController do
  require Logger

  use VaeWeb, :controller

  alias Vae.Rome

  def index(conn, _params) do
    render(conn, "index.html", romes: Rome.categories())
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
          romes: Rome.subcategories(rome),
          category: rome
        )

      Rome.is_subcategory?(rome) ->
        render(conn, "index.html",
          rome: rome,
          romes: Rome.romes(rome, [preload: [:certifications]]),
          category: Rome.category(rome),
          subcategory: rome
        )

      true ->
        redirect(conn, to: Routes.certification_path(conn, :index, rome_code: rome))
    end
  end
end
