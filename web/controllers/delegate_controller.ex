defmodule Vae.DelegateController do
  use Vae.Web, :controller

  alias Vae.Delegate

  filterable do
    @options param: :diplome
    filter certification(query, value, _conn) do
      query
      |> join(:inner, [c], d in assoc(c, :certifications))
      |> where([d, c], c.id == ^value)
    end
  end

  def index(conn, params) do
    query =
      Delegate
      |> where(is_active: true)
      |> order_by(asc: :name)

    with {:ok, filtered_query, filter_values} <- apply_filters(query, conn),
         page <- Repo.paginate(filtered_query, params) do
      render(conn, "index.html", delegates: page.entries, page: page, meta: filter_values)
    end
  end
end
