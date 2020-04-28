defmodule VaeWeb.DelegateController do
  use VaeWeb, :controller

  alias Vae.Delegate

  plug VaeWeb.Plugs.ApplicationAccess,
       [find_with_hash: :delegate_access_hash] when action in [:update]

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
         meta <- filter_values do
      render(conn, "index.html",
        delegates: page.entries,
        page: page,
        meta: meta
      )
    end
  end

  def show(conn, %{"id" => id} = _params) do
    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      delegate when not is_nil(delegate) <- Repo.get(Delegate, Vae.String.to_id(id))
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

  def update(conn, %{"id" => id} = params) do
    with(
      delegate when not is_nil(delegate) <- Repo.get(Delegate, Vae.String.to_id(id)),
      application <- conn.assigns[:current_application] |> Repo.preload(:delegate),
      true = application.delegate == delegate
    ) do
      {level, msg} =
        case Delegate.changeset(delegate, params["delegate"]) |> Repo.update() do
          {:ok, _delegate} -> {:success, "Coordonnées enregistrées"}
          {:error, error} -> {:error, "Une erreur est survenue: #{inspect(error)}"}
        end
      conn
      |> put_flash(level, msg)
      |> redirect(to: IO.inspect(Routes.user_application_path(conn, :show, application, %{hash: application.delegate_access_hash})))
    else
      _error ->
        raise Ecto.NoResultsError, queryable: Delegate
    end
  end
end
