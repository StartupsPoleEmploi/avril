defmodule Vae.CertificationController do
  require Logger
  use Vae.Web, :controller

  alias Vae.{Certification, Delegate, Rome}

  @search_client Application.get_env(:vae, :search_client)

  def cast_array(str), do: String.split(str, ",")

  filterable do
    @options default: [1, 2, 3, 4, 5], cast: &Vae.CertificationController.cast_array/1

    filter levels(query, value, _conn) do
      query |> where([c], c.level in ^value)
    end
  end

  def index(conn, params) do
    conn_updated = save_search_to_session(conn, params)

    if is_nil(params["search"]) do
      redirections(conn_updated, params)
    else
      if String.length(params["search"]["rome_code"]) > 0 do
        search_by_rome(conn_updated, params)
      else
        redirect(
          conn_updated,
          to:
            process_path(
              conn,
              :index,
              certification: params["search"]["certification"],
              lat: params["search"]["lat"],
              lng: params["search"]["lng"]
            )
        )
      end
    end
  end

  defp save_search_to_session(conn, params) do
    conn
    |> put_session(:search_query, params["search"]["query"])
    |> put_session(:search_profession, params["search"]["profession"])
    |> put_session(:search_certification, params["search"]["certification"])
    |> put_session(:search_rome, params["search"]["rome_code"])
    |> put_session(:search_geo, params["search"]["geolocation_text"])
    |> put_session(:search_lat, params["search"]["lat"])
    |> put_session(:search_lng, params["search"]["lng"])
    |> put_session(:search_county, params["search"]["county"])
    |> put_session(:search_postcode, params["search"]["postcode"])
    |> put_session(:search_administrative, params["search"]["administrative"])
  end

  defp list(conn, params) do
    page =
      Certification
      |> Repo.paginate(params)

    render(conn, "index.html", certifications: page.entries, page: page)
  end

  defp search_by_rome(conn, params) do
    params["search"]["rome_code"]
    |> get_rome(params["search"]["profession"])
    |> get_certifications_by_rome
    |> case do
      nil ->
        render(
          conn,
          Vae.CertificationView,
          "index.html",
          certifications: [],
          no_results: true,
          page: %Scrivener.Page{
            total_entries: 0,
            page_number: 0,
            total_pages: 0
          },
          profession: params["search"]["profession"]
        )

      rome ->
        certifications =
          rome
          |> assoc(:certifications)
          |> order_by(desc: :level)

        total_without_filter_level = Repo.aggregate(certifications, :count, :id)

        with {:ok, certifications_by_level, _filter_values} <-
               apply_filters(certifications, conn),
             page <- Repo.paginate(certifications_by_level, params) do
          render(
            conn,
            Vae.CertificationView,
            "index.html",
            certifications: page.entries,
            no_results: total_without_filter_level == 0,
            page: page,
            rome: rome,
            profession: rome.label,
            search: params["search"]
          )
        end
    end
  end

  defp get_rome(rome_code, _profession) do
    rome_code
  end

  defp get_certifications_by_rome(rome_id) do
    Repo.get_by(Rome, code: rome_id)
  end

  defp redirections(conn, params) do
    geo =
      case {params["lat"], params["lng"]} do
        {lat, lng} when lat != nil and lng != nil ->
          %{"_geoloc" => %{"lat" => lat, "lng" => lng}}

        _ ->
          nil
      end

    certification =
      case params["rncp_id"] do
        nil ->
          nil

        rncp_id ->
          Certification.search_by_rncp_id(rncp_id)
          |> Repo.one()
      end

    rome_id =
      case params["rome_code"] do
        nil ->
          nil

        rome_code ->
          Repo.get_by(Rome, code: rome_code)
          |> case do
            nil ->
              nil

            rome ->
              rome.id
          end
      end

    case {geo, certification, rome_id} do
      {_, nil, nil} ->
        list(conn, params)

      {_, nil, rome_id} ->
        redirect(
          conn,
          to: rome_path(conn, :certifications, rome_id)
        )

      {nil, certification, _} ->
        redirect(conn, to: process_path(conn, :index, certification: certification))

      {geo, certification, _} ->
        delegates = get_delegates(certification, geo["_geoloc"])

        if length(delegates) > 1 do
          delegate = Repo.preload(Repo.get(Delegate, hd(delegates).id), :process)

          redirect(
            conn,
            to:
              process_path(
                conn,
                :show,
                delegate.process,
                certification: certification,
                delegate: delegate,
                lat: params["delegate_search"]["lat"],
                lng: params["delegate_search"]["lng"]
              )
          )
        else
          redirect(
            conn,
            to:
              process_path(
                conn,
                :index,
                certification: certification,
                lat: params["delegate_search"]["lat"],
                lng: params["delegate_search"]["lng"]
              )
          )
        end
    end
  end

  defp get_delegates(certification, geo) do
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
