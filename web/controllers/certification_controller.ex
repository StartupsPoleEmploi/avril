defmodule Vae.CertificationController do
  require Logger
  use Vae.Web, :controller

  alias Vae.{Certification, Delegate, Rome, Places, ViewHelpers}

  @search_client Application.get_env(:vae, :search_client)

  def cast_array(str), do: String.split(str, ",")

  filterable do
    @options default: [1, 2, 3, 4, 5], cast: &Vae.CertificationController.cast_array/1

    filter levels(query, value, _conn) do
      query |> where([c], c.level in ^value)
    end

    @options param: :certificateur
    filter delegate(query, value, _conn) do
      query
      |> join(:inner, [d], d in assoc(d, :delegates))
      |> where([c, d], d.id == ^value)
    end
  end

  def index(conn, params) do
    conn_with_geo = save_geo_to_session(conn, params)

    if is_nil(params["rncp_id"]) do
      certifications_by_rome(conn_with_geo, params)
    else
      redirections(conn_with_geo, params)
    end
  end

  defp certifications_by_rome(conn, params) do
    case get_rome(params) do
      nil -> list(conn, params, Certification)
      rome -> list(conn, params, get_certifications_by_rome(rome))
    end
  end

  defp get_rome(%{"rome_id" => rome_id}) do
    Repo.get(Rome, rome_id)
  end

  defp get_rome(%{"rome_code" => rome_code}) do
    Repo.get_by(Rome, code: rome_code)
  end

  defp get_rome(_params) do
    nil
  end

  def get_certifications_by_rome(rome) do
    rome
    |> assoc(:certifications)
    |> order_by(desc: :level)
  end

  defp list(conn, params, certifications) do
    total_without_filter_level = Repo.aggregate(certifications, :count, :id)

    with {:ok, certifications_by_level, _filter_values} <- apply_filters(certifications, conn),
         page <- Repo.paginate(certifications_by_level, params) do
      render(
        conn,
        Vae.CertificationView,
        "index.html",
        certifications: page.entries,
        no_results: total_without_filter_level == 0,
        page: page
      )
    end
  end

  defp redirections(conn, params) do
    with certification when not is_nil(certification) <- get_certification(params),
         delegates <- get_delegates(certification, params) do
      if length(delegates) > 0 do
        delegate =
          Delegate
          |> Repo.get(hd(delegates).id)
          |> Repo.preload(:process)

        conn
        |> save_certification_to_session(certification)
        |> redirect(
          to:
            process_path(
              conn,
              :show,
              delegate.process,
              certification: certification,
              delegate: delegate
            )
        )
      else
        conn
        |> save_certification_to_session(certification)
        |> redirect(
          to:
            process_path(
              conn,
              :index,
              certification: certification
            )
        )
      end
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

  defp get_certification(params), do: Repo.one(Certification.search_by_rncp_id(params["rncp_id"]))

  defp get_delegates(certification, params) do
    geo = Map.take(params, ["lat", "lng"])

    certification
    |> Ecto.assoc(:certifiers)
    |> Repo.all()
    |> @search_client.get_delegates(geo)
    |> case do
      {:ok, delegates} ->
        delegates

      {:error, msg} ->
        Logger.error("Error on searching delegates: #{msg}")
        Delegate.from_certification(certification) |> Repo.all()
    end
  end
end
