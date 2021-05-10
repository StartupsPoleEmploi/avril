defmodule VaeWeb.DelegateController do
  use VaeWeb, :controller

  alias Vae.Delegate

  plug VaeWeb.Plugs.ApplicationAccess,
       [find_with_hash: :delegate_access_hash] when action in [:update]

  def geo(conn, %{"administrative" => administrative_slug}) do
    cities = base_delegate_query(conn)
      |> where([f], fragment("slugify(?)", f.administrative) == ^administrative_slug)
      |> distinct([f], f.city)
      |> select([f], [f.administrative, f.city])
      |> order_by([f], f.city)
      |> Repo.all()

    if length(cities) > 0 do
      render(conn, "geo.html",
        administrative: cities |> List.first() |> List.first(),
        cities: cities |> Enum.map(fn [_a, c] -> c end),
        is_prc: is_prc_controller(conn)
      )
    else
      warning_and_redirect(conn)
    end
  end

  def geo(conn, _params) do
    administratives = base_delegate_query(conn)
      |> distinct([f], f.administrative)
      |> select([f], f.administrative)
      |> order_by([f], f.administrative)
      |> Repo.all()
      |> Enum.filter(&(not is_nil(&1)))

    if length(administratives) > 0 do
      render(conn, "geo.html",
        administratives: administratives,
        is_prc: is_prc_controller(conn)
      )
    else
      warning_and_redirect(conn)
    end
  end

  def index(conn, params) do
    administrative_slug = Map.get(params, "administrative")
    city_slug = Map.get(params, "city")

    query =
      base_delegate_query(conn)
      |> Vae.Maybe.if(
        not is_nil(administrative_slug),
        &where(&1, [f], fragment("slugify(?)", f.administrative) == ^administrative_slug)
      )
      |> Vae.Maybe.if(
        not is_nil(city_slug),
        &where(&1, [f], fragment("slugify(?)", f.city) == ^city_slug)
      )
      |> order_by(asc: :name)

    first_result = Repo.all(query |> limit(1)) |> List.first()

    if first_result do
      with page <- Repo.paginate(query, Map.merge(params, %{
        page_size: 18
      })) do
        render(conn, "index#{if is_prc_controller(conn), do: "_prc"}.html",
          administrative_slug: administrative_slug,
          city_slug: city_slug,
          administrative: first_result.administrative,
          city: first_result.city,
          delegates: page.entries,
          page: page
        )
      end
    else
      warning_and_redirect(conn)
    end
  end

  def show(conn, %{"id" => id} = params) do
    administrative_slug = Map.get(params, "administrative")
    city_slug = Map.get(params, "city")

    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      delegate when not is_nil(delegate) <- Repo.get!(Delegate, id)
    ) do
      real_administrative_slug = Vae.String.parameterize(delegate.administrative)
      real_city_slug = Vae.String.parameterize(delegate.city)
      if(
        delegate.slug == slug &&
        real_administrative_slug == administrative_slug &&
        real_city_slug == city_slug) do
          render(conn, "show.html",
            delegate: delegate
          )
      else
        # Metadata is not up-to-date
        redirect(conn, to: Routes.delegate_path(conn, :show, real_administrative_slug, real_city_slug, delegate, conn.query_params))
      end
    end
  end

  def update(conn, %{"id" => id} = params) do
    with(
      delegate when not is_nil(delegate) <- Repo.get!(Delegate, Vae.String.to_id(id)),
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
    end
  end

  defp warning_and_redirect(conn) do
    conn
    |> put_flash(:warning, "Aucun certificateur n'a été trouvé dans cette zone.")
    |> redirect(to: Routes.delegate_path(conn, :geo))
  end

  defp is_prc_controller(conn) do
    String.starts_with?(conn.request_path, "/point-relais-conseil-vae")
  end

  defp base_delegate_query(conn) do
    Delegate
    |> where(is_active: true)
    |> Vae.Maybe.if(is_prc_controller(conn),
      &where(&1, is_prc: true),
      # TODO: make query more dynamic
      &where(&1, [q], fragment("EXISTS (
        SELECT 1 from certifications_delegates where certifications_delegates.delegate_id = ?
      )", q.id))
    )
  end
end
