defmodule Vae.ProcessController do
  use Vae.Web, :controller

  alias Vae.Certification
  alias Vae.Delegate

  def index(conn, params) do
    certification =
      case params["certification"] do
        nil ->
          nil

        certification_id ->
          Repo.get(Certification, certification_id)
      end

    update_wizard_trails(conn, step: 3, url: "/processes")
    |> render(
      "index.html",
      certification: certification
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

    update_wizard_trails(conn, step: 3, url: "/processes")
    |> render(
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
        %{"lat" => lat, "lng" => lng} when lat != nil and lng != nil and lat != "" and lng != "" ->
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

    IO.inspect(length(delegates), label: "prout")

    if length(delegates) > 1 do
      delegate = Repo.get(Delegate, hd(delegates).id) |> Repo.preload(:process)

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
    certification =
      case params["certification"] do
        nil -> nil
        certification_id -> Repo.get(Certification, certification_id)
      end

    delegate =
      case params["delegate"] do
        nil -> nil
        delegate_id -> Repo.get(Delegate, delegate_id) |> Repo.preload(:process)
      end

    conn
    |> update_wizard_trails(step: 4, url: "/")
    |> render(
      "index.html",
      certification: certification,
      delegate: delegate,
      lat: params["lat"],
      lng: params["lng"]
    )
  end
end
