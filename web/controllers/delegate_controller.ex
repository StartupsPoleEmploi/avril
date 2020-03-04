defmodule Vae.DelegateController do
  use Vae.Web, :controller

  alias Vae.Certification
  alias Vae.Delegate

  filterable do
    @options param: :diplome
    filter certification(query, value, _conn) do
      query
      |> join(:inner, [c], d in assoc(c, :certifications))
      |> where([d, c], c.id == ^Vae.String.to_id(value))
    end
  end

  def index(conn, params) do
    query =
      Delegate
      |> where(is_active: true)
      |> order_by(asc: :name)

    with {:ok, filtered_query, filter_values} <- apply_filters(query, conn),
         page <- Repo.paginate(filtered_query, params),
         meta <- enrich_filter_values(Vae.Map.params_with_ids(filter_values)) do
      render(conn, "index.html",
        delegates: page.entries,
        page: page, meta: meta,
        with_search: true
      )
    end
  end

  def show(conn, %{"id" => id} = _params) do
    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      delegate when not is_nil(delegate) <- Repo.get(Delegate, id)
    ) do
      if delegate.slug != slug do
        # Slug is not up-to-date
        redirect(conn, to: Routes.delegate_path(conn, :show, delegate, conn.query_params))
      else
        render(conn, "show.html",
          delegate: delegate,
          certifications: Delegate.get_certifications(delegate)
        )
      end
    else
      _error ->
        raise Ecto.NoResultsError, queryable: Delegate
    end

  end

  defp enrich_filter_values(filter_values) do
    with {_get, updated_values} <-
           Map.get_and_update(filter_values, :certification, &update_certification/1) do
      updated_values
    end
  end

  defp update_certification(certification) do
    {certification, Certification.get(certification)}
  end
end
