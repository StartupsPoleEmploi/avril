defmodule VaeWeb.DelegateController do
  use VaeWeb, :controller

  alias Vae.Delegate

  plug VaeWeb.Plugs.ApplicationAccess,
       [find_with_hash: :delegate_access_hash] when action in [:update]

  def geo(conn, %{"administrative" => administrative_slug}) do
    cities = Delegate
      |> where(is_active: true)
      |> where([f], fragment("slugify(?)", f.administrative) == ^administrative_slug)
      |> distinct([f], f.city)
      |> select([f], [f.administrative, f.city])
      |> order_by([f], f.city)
      |> Repo.all()

    if length(cities) > 0 do
      render(conn, "geo.html",
        administrative: cities |> List.first() |> List.first(),
        cities: cities |> Enum.map(fn [_a, c] -> c end)
      )
    else
      raise Ecto.NoResultsError, queryable: Delegate
    end
  end
  def geo(conn, _params) do
    administratives = Delegate
      |> where(is_active: true)
      |> distinct([f], f.administrative)
      |> select([f], f.administrative)
      |> order_by([f], f.administrative)
      |> Repo.all()
      |> Enum.filter(&(not is_nil(&1)))

    if length(administratives) > 0 do
      render(conn, "geo.html",
        administratives: administratives
      )
    else
      raise Ecto.NoResultsError, queryable: Delegate
    end
  end

  def index(conn, %{"administrative" => administrative_slug, "city" => city_slug} = params) do
    query =
      Delegate
      |> where(is_active: true)
      |> where([f], fragment("slugify(?)", f.administrative) == ^administrative_slug)
      |> where([f], fragment("slugify(?)", f.city) == ^city_slug)
      |> order_by(asc: :name)

    first_result = Repo.all(query |> limit(1)) |> List.first()

    if first_result do
      with {:ok, filtered_query, filter_values} <- apply_filters(query, conn),
           page <- Repo.paginate(filtered_query, params),
           meta <- filter_values do
        render(conn, "index.html",
          administrative_slug: administrative_slug,
          city_slug: city_slug,
          administrative: first_result.administrative,
          city: first_result.city,
          delegates: page.entries,
          page: page,
          meta: meta
        )
      end
    else
      raise Ecto.NoResultsError, queryable: Delegate
    end
  end

  def show(conn, %{"administrative" => administrative_slug, "city" => city_slug, "id" => id} = _params) do
    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      delegate when not is_nil(delegate) <- Repo.get(Delegate, id)
    ) do
      real_administrative_slug = Vae.String.parameterize(delegate.administrative)
      real_city_slug = Vae.String.parameterize(delegate.city)
      if(
        delegate.slug == slug &&
        real_administrative_slug == administrative_slug &&
        real_city_slug == city_slug) do
          render(conn, "show.html",
            delegate: delegate,
            certifications: Delegate.get_certifications(delegate)
          )
      else
        # Metadata is not up-to-date
        redirect(conn, to: Routes.delegate_path(conn, :show, real_administrative_slug, real_city_slug, delegate, conn.query_params))
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
      |> redirect(to: Routes.user_application_path(conn, :show, application, %{hash: application.delegate_access_hash}))
    else
      _error ->
        raise Ecto.NoResultsError, queryable: Delegate
    end
  end
end
