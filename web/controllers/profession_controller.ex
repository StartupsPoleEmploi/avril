defmodule Vae.ProfessionController do
  require Logger

  use Vae.Web, :controller

  alias Vae.Profession

  filterable do
    @options param: [:sort, :order], default: [sort: :label, order: :asc]
    filter search(query, %{sort: field, order: order}, _conn) do
      query |> order_by([{^order, ^field}])
    end
  end

  def index(conn, params) do
    with {:ok, query, filter_values} <- apply_filters(Profession, conn),
      page <- Repo.paginate(query, params),
     do:

      render(conn, "index.html",
        professions: page.entries |> Repo.preload(:rome),
        meta: filter_values,
        page: page,
        with_search: false
      )
  end
end
