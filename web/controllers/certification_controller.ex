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
    if is_nil(params["rncp_id"]) do
      certifications_by_rome(conn, params)
    else
      redirections(conn, params)
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
    certification = Certification.search_by_rncp_id(params["rncp_id"]) |> Repo.one()

    delegates = get_delegates(certification, %{"lat" => params["lat"], "lng" => params["lng"]})

    if length(delegates) > 1 do
      delegate =
        Delegate
        |> Repo.get(hd(delegates).id)
        |> Repo.preload(:process)

      redirect(
        conn,
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
      redirect(
        conn,
        to:
          process_path(
            conn,
            :index,
            certification: certification
          )
      )
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
