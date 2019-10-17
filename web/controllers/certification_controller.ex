defmodule Vae.CertificationController do
  require Logger
  use Vae.Web, :controller

  alias Vae.{Application, Certification, Delegate, JobSeeker, Places, Rome, SearchDelegate, User, ViewHelpers}

  def cast_array(str), do: String.split(str, ",")

  filterable do
    @options param: :levels,
             default: [1, 2, 3, 4, 5],
             cast: &Vae.CertificationController.cast_array/1
    filter levels(query, value, _conn) do
      query |> where([c], c.level in ^value)
    end

    @options param: :certificateur
    filter delegate(query, value, _conn) do
      query
      |> join(:inner, [d], d in assoc(d, :delegates))
      |> where([c, d], d.id == ^Vae.String.to_id(value))
    end

    @options param: :metier
    filter rome(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.id == ^Vae.String.to_id(value))
    end

    @options param: :rome_code
    filter rome_code(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.code == ^value)
    end
  end

  def index(conn, params) do
    if Map.has_key?(conn.query_params, "rome") do
      # using the old ?rome=ID instead of ?metier=ID
      redirect(conn, to: Routes.certification_path(conn, :index, Map.put_new(Map.delete(conn.query_params, "rome"), "metier", conn.query_params["rome"])))
    else

      conn_with_geo = save_geo_to_session(conn, params)

      if is_nil(params["rncp_id"]) do
        list(conn_with_geo, params)
      else
        redirections(conn_with_geo, params)
      end
    end
  end

  def show(conn, params) do
    case Integer.parse(params["id"]) do
      {id, rest} ->
        slug = Regex.replace(~r/^\-/, rest, "")
        certification = Certification.get_certification(id)
        if certification.slug != slug do
          # Slug is not up-to-date
          redirect(conn, to: Routes.certification_path(conn, :show, certification, conn.query_params))
        else
          delegate =
           get_delegate(%{
              "certificateur" => Vae.String.to_id(params["certificateur"]),
              geo: %{
                "lat" => get_session(conn, :search_lat),
                "lng" => get_session(conn, :search_lng)
              },
              postcode: get_session(conn, :search_postcode),
              administrative: get_session(conn, :search_administrative)
            }, certification)

          redirect_or_show(conn, certification, delegate, is_nil(params["certificateur"]))
        end
      :error ->
        raise Ecto.NoResultsError, queryable: Certification
    end
  end

  def select(conn, %{"certification_id" => certification_id} = params) do
    certification_id = Vae.String.to_id(certification_id)
    delegate_id =
      Vae.String.to_id(params["delegate_id"]) ||
      Vae.String.to_id(params["certificateur"]) ||
      ((get_delegate(%{
        geo: %{
          "lat" => get_session(conn, :search_lat),
          "lng" => get_session(conn, :search_lng)
        },
        postcode: get_session(conn, :search_postcode),
        administrative: get_session(conn, :search_administrative)
      }, Repo.get(Certification, certification_id)) || %{}) |> Map.get(:id))

    if Coherence.logged_in?(conn) do
      {:ok, application} = Application.find_or_create_with_params(%{
        certification_id: certification_id,
        delegate_id: delegate_id,
        user_id: Coherence.current_user(conn).id
      })
      conn
      |> put_flash(
          :success,
          "Votre candidature a bien été créée. Nous vous invitons désormais à compléter votre profil et transmettre votre dossier."
        )
      |> redirect(to: Routes.application_path(conn, :show, application))
    else
      conn
      |> put_session(:certification_id, certification_id)
      |> put_session(:delegate_id, delegate_id)
      |> redirect(to: Routes.registration_path(conn, :new))
    end
  end

  defp redirect_or_show(conn, certification, nil, _has_delegate) do
    redirect(
      conn,
      to:
        Routes.delegate_path(
          conn,
          :index,
          diplome: certification
        )
    )
  end

  defp redirect_or_show(conn, certification, delegate, true) do
    redirect(
      conn,
      to:
        Routes.certification_path(
          conn,
          :show,
          certification,
          certificateur: delegate
        )
    )
  end

  defp redirect_or_show(conn, certification, delegate, _has_delegate) do
    render(
      conn,
      "show.html",
      certification: certification,
      delegate: delegate,
      is_asp: Delegate.is_asp?(delegate),
      user_changeset: User.changeset(%User{}, %{}),
      job_seeker_changeset: JobSeeker.changeset(%JobSeeker{}, %{}),
      with_search: true
    )
  end

  defp list(conn, params) do
    with {:ok, filtered_query, filter_values} <- apply_filters(Certification, conn),
         page <- Repo.paginate(filtered_query, params),
         meta <- enrich_filter_values(Vae.Map.params_with_ids(filter_values)) do
      render(
        conn,
        "index.html",
        certifications: page.entries,
        no_results: count_without_level_filter(params) == 0,
        page: page,
        meta: meta,
        with_search: true
      )
    end
  end

  defp enrich_filter_values(filter_values) do
    filter_values
    |> Map.drop([:rome_code])
    |> Map.put(:rome, get_rome(filter_values))
    |> Map.put(:delegate, get_delegate(filter_values, nil))
  end

  defp get_rome(%{rome: r}) when not is_nil(r), do: Rome.get(r)
  defp get_rome(%{rome_code: rc}) when not is_nil(rc), do: Rome.get_by_code(rc)
  defp get_rome(_), do: nil

  defp count_without_level_filter(params) do
    conn_without_filter_level = %Plug.Conn{
      params: Map.drop(params, ["levels"])
    }

    with {:ok, filtered_query, _filter_values} <-
           apply_filters(
             Certification,
             conn_without_filter_level
           ) do
      Repo.aggregate(filtered_query, :count, :id)
    end
  end

  defp redirections(conn, params) do
    postcode = get_session(conn, :search_postcode)
    administrative = get_session(conn, :search_administrative)

    with certification when not is_nil(certification) <- Certification.get_certification(params),
         delegate <- SearchDelegate.get_delegate(certification, params, postcode, administrative) do
      conn
      |> save_certification_to_session(certification)
      |> redirect(
        to:
          Routes.certification_path(
            conn,
            :show,
            certification,
            certificateur: delegate
          )
      )
    else
      _ ->
        conn
        |> save_rome_to_session(params)
        |> redirect(
          to:
            Routes.certification_path(
              conn,
              :index,
              rome_code: params["rome_code"]
            )
        )
    end
  end

  defp get_delegate(%{delegate: d}, nil) when not is_nil(d), do: Delegate.get(d)

  defp get_delegate(%{"certificateur" => delegate_id}, _certification)
       when not (is_nil(delegate_id) or delegate_id == "") do
    Delegate
    |> Repo.get(delegate_id)
    |> Repo.preload(:process)
  end

  defp get_delegate(%{geo: %{"lat" => lat, "lng" => lng} = geo} = params, certification)
       when not (is_nil(lat) or is_nil(lng)) do
    SearchDelegate.get_delegate(
      certification,
      geo,
      params[:postcode],
      params[:administrative]
    )
  end

  defp get_delegate(_params, _certification), do: nil

  defp save_rome_to_session(conn, params) do
    conn
    |> put_session(:search_query, params["romelabel"])
    |> put_session(:search_profession, params["romelabel"])
    |> put_session(:search_rome, params["rome_code"])
  end

  defp save_certification_to_session(conn, certification) do
    conn
    |> put_session(:search_query, ViewHelpers.format_certification_label(certification))
    |> put_session(:search_certification, certification.id)
  end

  defp save_geo_to_session(conn, %{"lat" => lat, "lng" => lng} = params) do
    place = Places.get_geoloc_from_geo(params)

    conn
    |> put_session(:search_geo, List.first(place["city"]))
    |> put_session(:search_lat, lat)
    |> put_session(:search_lng, lng)
    |> put_session(:search_county, List.first(place["county"]))
    |> put_session(:search_postcode, List.first(place["postcode"]))
    |> put_session(:search_administrative, List.first(place["administrative"]))
  end

  defp save_geo_to_session(conn, _params), do: conn
end
