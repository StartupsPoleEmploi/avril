defmodule Vae.DelegateController do
  use Vae.Web, :controller

  alias Vae.Delegate
  alias Vae.Certification

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

  def show(conn, %{"id" => id, "certification" => certification_id}) do
    certification = Repo.get!(Certification, certification_id)
    render_result(conn, id, certification)
  end

  def show(conn, %{"id" => id}) do
    render_result(conn, id, nil)
  end

  defp render_result(conn, id, certification) do
    delegate =
      Repo.get!(Delegate, id)
      |> Repo.preload(:process)

    render(conn, "show.html", delegate: delegate, certification: certification)
  end
end
