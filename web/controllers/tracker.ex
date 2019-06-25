defmodule Vae.Tracker do
  require Logger
  import Plug.Conn

  alias Vae.{Analytic, JobSeeker, Search, Visit}
  alias Vae.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, new_conn, job_seeker} <- get_job_seeker(conn),
         {state, func, analytic} when state in [:new, :old] <-
           init_tracking({new_conn, job_seeker}),
         {:ok, updated_analytic} <- track({new_conn, {func, analytic}}) do
      job_seeker
      |> JobSeeker.update_analytics_changeset(state, updated_analytic)
      |> Repo.update!()

      new_conn
    else
      {_, conn} -> conn
    end
  end

  def get_job_seeker(%Plug.Conn{request_path: "/", query_params: %{"js_id" => js_id}} = conn) do
    with job_seeker when not is_nil(job_seeker) <- Repo.get(JobSeeker, js_id),
         new_conn <- put_session(conn, :js_id, job_seeker.id) do
      {:ok, new_conn, job_seeker}
    else
      _ -> {:no_job_seeker, conn}
    end
  end

  def get_job_seeker(conn) do
    with js_id when not is_nil(js_id) <- get_session(conn, :js_id),
         job_seeker <- Repo.get(JobSeeker, js_id) do
      {:ok, conn, job_seeker}
    else
      _ -> {:no_job_seeker, conn}
    end
  end

  def init_tracking({conn, job_seeker}) do
    case JobSeeker.init_analytic(job_seeker) do
      {:new, analytic} ->
        {:new, &Analytic.create_visits_changeset/2, analytic}

      {:old, analytic} ->
        {:old, &Analytic.update_visits_changeset/2, analytic}

      {:error, job_seeker} ->
        Logger.info(
          "Error on job_seeker: #{job_seeker.id}, multiple analytics found for the same day"
        )

        {:error, conn}
    end
  end

  def track({%Plug.Conn{request_path: path, path_info: _path_info} = _conn, {_func, analytic}})
      when path == "/",
      do: {:ok, analytic}

  def track({%Plug.Conn{request_path: "/"} = _conn, {_func, analytic}}),
    do: {:ok, analytic}

  def track({%Plug.Conn{query_params: query_params} = conn, {func, analytic}})
      when query_params != %{} do
    updated_analytic =
      func.(
        analytic,
        %Visit{
          path_info: conn.path_info,
          certification_id: Map.get(query_params, "certification"),
          delegate_id: Map.get(query_params, "delegate"),
          search: build_search(query_params)
        }
      )

    {:ok, updated_analytic}
  end

  defp build_search(%{"search" => search}) when search != %{} do
    %Search{
      geolocation_text: search["geolocation_text"],
      lat: search["lat"],
      lng: search["lng"],
      profession: search["profession"],
      rome_code: search["rome_code"]
    }
  end

  defp build_search(_), do: nil
end
