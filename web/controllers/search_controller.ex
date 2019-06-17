defmodule Vae.SearchController do
  require Logger
  use Vae.Web, :controller

  alias Vae.Certification
  alias Vae.SearchDelegate

  def search(conn, params) do
    conn
    |> save_search_to_session(params)
    |> redirect_to_result(params)
  end

  defp redirect_to_result(conn, %{"search" => %{"rome_code" => r, "certification" => ""}}) do
    redirect(
      conn,
      to:
        Routes.certification_path(
          conn,
          :index,
          rome_code: r
        )
    )
  end

  defp redirect_to_result(conn, %{"search" => %{"rome_code" => _r, "certification" => c} = search}) do
    with certification when not is_nil(certification) <- Certification.get_certification(c),
         delegate <-
           SearchDelegate.get_delegate(
             certification,
             Map.take(search, ["lat", "lng"]),
             search["postcode"],
             search["administrative"]
           ) do
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
end
