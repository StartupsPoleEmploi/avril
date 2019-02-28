defmodule Vae.CertificationController do
  require Logger
  use Vae.Web, :controller

  alias Vae.Certification
  alias Vae.Delegate
  alias Vae.Places
  alias Vae.ViewHelpers
  alias Vae.SearchDelegate

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
      |> where([c, d], d.id == ^value)
    end

    @options param: :rome
    filter rome(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.id == ^value)
    end

    @options param: :rome_code
    filter rome_code(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.code == ^value)
    end
  end

  def index(conn, params) do
    conn_with_geo = save_geo_to_session(conn, params)

    if is_nil(params["rncp_id"]) do
      list(conn_with_geo, params)
    else
      redirections(conn_with_geo, params)
    end
  end

  def show(conn, params) do
    certification = Certification.get_certification(params["id"])

    delegate =
      Map.take(params, ["certificateur"])
      |> Map.put_new(:geo, %{
        "lat" => Plug.Conn.get_session(conn, :search_lat),
        "lng" => Plug.Conn.get_session(conn, :search_lng)
      })
      |> Map.put_new(:postcode, Plug.Conn.get_session(conn, :search_postcode))
      |> Map.put_new(:administrative, Plug.Conn.get_session(conn, :search_administrative))
      |> get_delegate(certification)

    redirect_or_show(conn, certification, delegate, is_nil(params["certificateur"]))
  end

  defp redirect_or_show(conn, certification, nil, _has_delegate) do
    redirect(
      conn,
      to:
        delegate_path(
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
        certification_path(
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
      delegate: delegate
    )
  end

  defp list(conn, params) do
    with {:ok, filtered_query, filter_values} <- apply_filters(Certification, conn),
         page <- Repo.paginate(filtered_query, params) do
      render(
        conn,
        Vae.CertificationView,
        "index.html",
        certifications: page.entries,
        no_results: count_without_level_filter(params) == 0,
        page: page,
        meta: filter_values
      )
    end
  end

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
    postcode = Plug.Conn.get_session(conn, :search_postcode)
    administrative = Plug.Conn.get_session(conn, :search_administrative)

    with certification when not is_nil(certification) <- Certification.get_certification(params),
         delegate <- SearchDelegate.get_delegate(certification, params, postcode, administrative) do
      conn
      |> save_certification_to_session(certification)
      |> redirect(
        to:
          certification_path(
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
            certification_path(
              conn,
              :index,
              rome_code: params["rome_code"]
            )
        )
    end
  end

  defp get_delegate(%{"certificateur" => delegate_id}, _certification) do
    Delegate
    |> Repo.get(delegate_id)
    |> Repo.preload(:process)
  end

  defp get_delegate(%{geo: %{"lat" => lat, "lng" => lng} = geo} = params, certification)
       when not (is_nil(lat) or is_nil(lng)) do
    SearchDelegate.get_delegate(
      certification,
      geo,
      params["postcode"],
      params["administrative"]
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
