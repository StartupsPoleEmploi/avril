defmodule Vae.ProcessController do
  use Vae.Web, :controller

  alias Vae.Certification
  alias Vae.Delegate

  def index(conn, params) do
    search(
      conn,
      Map.merge(params, %{
        "delegate_search" => %{"lat" => params["lat"], "lng" => params["lng"]}
      })
    )
  end

  def delegates(conn, params) do
    certification =
      case params["certification"] do
        nil ->
          nil

        certification_id ->
          Repo.get(Certification, certification_id)
      end

    render(
      conn,
      "delegates.html",
      certification: certification,
      profession: params["search"]["profession"],
      delegates: get_delegates(certification, %{lat: params["lat"], lng: params["lng"]}),
      lat: params["lat"],
      lng: params["lng"]
    )
  end

  def get_delegates(certification, geo) do
    algolia_filters = [
      {:filters, "certifier_id:#{certification.certifier_id} AND is_active:true"}
    ]

    algolia_geo =
      case geo do
        %{lat: lat, lng: lng} when lat != nil and lng != nil ->
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

  def search(conn, params) do
    certification =
      case params["certification"] do
        nil -> nil
        certification_id -> Repo.get(Certification, certification_id)
      end

    algolia_filters = [
      {:filters, "certifier_id:#{certification.certifier_id} AND is_active:true"}
    ]

    algolia_geo =
      case params["delegate_search"] do
        %{"lat" => lat, "lng" => lng} when lat != "" and lng != "" ->
          [{:aroundLatLng, [lat, lng]}]

        _ ->
          []
      end

    delegates =
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

  def show(conn, params) do
    render(
      conn,
      "index.html",
      certification: get_certification(params["certification"]),
      delegate: get_delegate(params["delegate"]),
      lat: params["lat"],
      lng: params["lng"]
    )
  end

  def get_certification(nil), do: nil
  def get_certification(certification_id), do: Repo.get(Certification, certification_id)

  def get_delegate(nil), do: nil
  def get_delegate(delegate_id), do: Delegate |> Repo.get(delegate_id) |> Repo.preload(:process)
end
