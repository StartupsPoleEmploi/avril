defmodule Vae.SearchController do
  require Logger
  use Vae.Web, :controller

  def search(conn, params) do
    conn_updated = save_search_to_session(conn, params)

    if String.length(params["search"]["rome_code"]) > 0 do
      redirect(
        conn_updated,
        to:
          certification_path(
            conn,
            :index,
            rome_code: params["search"]["rome_code"]
          )
      )
    else
      redirect(
        conn_updated,
        to:
          process_path(
            conn,
            :index,
            certification: params["search"]["certification"]
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
