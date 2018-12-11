defmodule Vae.ProcessController do
  use Vae.Web, :controller

  require Logger

  alias Vae.Certification
  alias Vae.Delegate

  @search_client Application.get_env(:vae, :search_client)

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

  def search(conn, params) do
    certification =
      case params["certification"] do
        nil -> nil
        certification_id -> Repo.get(Certification, certification_id) |> Repo.preload(:certifiers)
      end

    case get_delegates(certification, params["delegate_search"]) do
      [head | _tail = []] ->
        delegate = preload_process(head)

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

      delegates ->
        delegate =
          delegates
          |> filter_delegates_from_postalcode(get_session(conn, :search_postcode))
          |> filter_delegates_from_administrative_if_no_postcode_found(
            get_session(conn, :search_administrative)
          )
          |> select_near_delegate()

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

  defp filter_delegates_from_postalcode(delegates, search_postcode) do
    filtered_delegates =
      delegates
      |> Enum.filter(fn delegate ->
        case delegate.geolocation["postcode"] do
          [] ->
            false

          [postcode | _tail] ->
            String.slice(postcode, 0..1) == String.slice(search_postcode, 0..1)
        end
      end)

    {filtered_delegates, delegates}
  end

  defp filter_delegates_from_administrative_if_no_postcode_found(
         {[], delegates},
         administrative
       ) do
    filtered_delegates =
      delegates
      |> Enum.filter(fn %{geolocation: %{"administrative" => [delegate_administrative]}} ->
        delegate_administrative == administrative
      end)

    {filtered_delegates, delegates}
  end

  defp filter_delegates_from_administrative_if_no_postcode_found(tuple, _administrative),
    do: tuple

  defp select_near_delegate({[], [delegate | _delegates]}), do: preload_process(delegate)
  defp select_near_delegate({[delegate | _], _delegates}), do: preload_process(delegate)

  defp preload_process(delegate),
    do: Repo.get(Delegate, delegate.id) |> Repo.preload(:process)
end
