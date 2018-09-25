defmodule Vae.CertificationController do
  use Vae.Web, :controller

  alias Vae.{Certification, Delegate, Rome}
  alias Vae.Suggest

  def index(conn, params) do
    conn_updated =
      conn
      |> put_session(:search_job, params["search"]["profession"])
      |> put_session(:search_rome, params["search"]["rome_code"])
      |> put_session(:search_geo, params["search"]["geolocation_text"])
      |> put_session(:search_lat, params["search"]["lat"])
      |> put_session(:search_lng, params["search"]["lng"])

    case params["search"]["rome_code"] do
      nil -> redirections(conn_updated, params)
      _ -> search_by_rome(conn_updated, params)
    end
  end

  defp list(conn, params) do
    page =
      Certification
      |> Repo.paginate(params)

    render(conn, "list.html", certifications: page.entries, page: page)
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
          page: %Scrivener.Page{total_entries: 0},
          profession: params["search"]["profession"]
        )

      rome ->
        page =
          rome
          |> assoc(:certifications)
          |> order_by(desc: :level)
          |> Repo.paginate(params)

        render(
          conn,
          Vae.CertificationView,
          "index.html",
          certifications: page.entries,
          page: page,
          rome: rome,
          profession: rome.label,
          search: params["search"]
        )
    end
  end

  defp get_rome("", profession) do
    {:ok, professions} = Suggest.get_suggest(profession)

    professions
    |> Enum.at(0)
    |> case do
      nil -> ""
      professions -> professions |> Map.get("id")
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
        nil -> nil
        rncp_id -> Certification |> where(rncp_id: ^rncp_id) |> first() |> Repo.one()
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

  # TODO: Need to extract this shit used in process_controller
  defp get_delegates(certification, geo) do
    algolia_filters = [
      {:filters, "certifier_id:#{certification.certifier_id} AND is_active:true"}
    ]

    algolia_geo =
      case geo do
        %{"lat" => lat, "lng" => lng} when lat != nil and lng != nil ->
          [{:aroundLatLng, [lat, lng]}]

        _ ->
          []
      end

    case "delegate" |> Algolia.search("", algolia_filters ++ algolia_geo) do
      {:ok, response} ->
        response
        |> Map.get("hits")
        |> Enum.map(fn item ->
          item
          |> Enum.reduce(%{}, fn {key, val}, acc ->
            Map.put(acc, String.to_atom(key), val)
          end)
        end)

      _ ->
        Delegate.from_certification(certification) |> Repo.all()
    end
  end
end
