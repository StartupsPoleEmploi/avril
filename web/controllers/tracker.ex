defmodule Vae.Tracker do
  require Logger
  import Plug.Conn

  alias Vae.JobSeeker
  alias Vae.Repo.NewRelic, as: Repo

  def init(opts), do: opts

  def call(conn, opts) do
    with {:ok, new_conn, job_seeker} <- get_job_seeker(conn),
         #         {:ok, _, analytic} <- start_tracking({new_conn, job_seeker}),
         {state, func, analytic} when state in [:new, :old] <-
           start_tracking({new_conn, job_seeker}),
         {:ok, updated_analytic} <- track_user_journey_from_params({new_conn, {func, analytic}}) do
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

  def start_tracking({conn, job_seeker}) do
    case JobSeeker.init_analytic(job_seeker) do
      {:new, analytic} ->
        {:new, &create_user_journey/2, analytic}

      {:old, analytic} ->
        {:old, &update_user_journey/2, analytic}

      {:error, job_seeker} ->
        Logger.info(
          "Error on job_seeker: #{job_seeker.id}, multiple analytics found for the same day"
        )

        {:error, conn}

      _ ->
        {:no_job_seeker, conn}
    end
  end

  def create_user_journey(analytic, params) do
    analytic
    |> Ecto.Changeset.change(params)
    |> Ecto.Changeset.cast_embed(:visits)
  end

  def update_user_journey(analytic, visit) do
    analytic
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:visits, [visit | analytic.visits])
    |> Ecto.Changeset.apply_changes()
  end

  def track_user_journey_from_params({%Plug.Conn{request_path: "/"} = conn, {func, analytic}}),
    do: {:ok, analytic}

  def track_user_journey_from_params(
        {%Plug.Conn{query_params: %{"search" => search}} = conn, {func, analytic}}
      )
      when search != %{} do
    updated_analytic =
      func.(analytic, %Vae.Visit{
        search: %Vae.Search{
          geolocation_text: search["geolocation_text"],
          lat: search["lat"],
          lng: search["lng"],
          profession: search["profession"],
          rome_code: search["rome_cpde"]
        }
      })

    {:ok, updated_analytic}
  end

  # %{
  #    analytics: [
  #    %{
  #      time: Date.utc_today(),
  #      visits: [
  #        %{
  #          path_info: ["profession", "suggest"],
  #          search:
  #            %{
  #              rome_code: "K1412",
  #              profession: "plop",
  #              geolocation_text: "Paris 2e Arrondissement"
  #            } || %{},
  #          certification_id: "2001" || nil,
  #          delegate_id: "10" || nil
  #        }
  #      ]
  #    }
  #  ]
  # }
  def track_user_journey_from_params({%Plug.Conn{query_params: %{}} = conn, _}), do: conn

  def track_user_journey_from_params(
        {%Plug.Conn{path_info: ["professions", "_suggest"]} = conn, _}
      ),
      do: conn

  # query_params: %{
  #  "_utf8" => "✓",
  #  "search" => %{
  #    "geolocation_text" => "Paris 2e Arrondissement",
  #    "lat" => "48.8668",
  #    "lng" => "2.3405",
  #    "profession" => "Boucherie (Boucher / Bouchère, ...)",
  #    "rome_code" => "D1101"
  #  }
  # }
  def track_user_journey_from_params(
        {%Plug.Conn{
           query_params: %{
             "search" => search
           }
         } = conn, analytic}
      ) do
  end

  # query_params: %{
  #  "certification" => "2001",
  #  "lat" => "48.8668",
  #  "lng" => "2.3405",
  #  "search" => %{"profession" => "Boucherie (Boucher / Bouchère, ...)"}
  # },
  def track_user_journey_from_params(
        {%Plug.Conn{query_params: %{"certification" => certification_id}} = conn, analytic}
      ) do
    updated_analytic = put_in(analytic, [Access.key(:visits), :cerification_id], certification_id)
    {:ok, updated_analytic}
  end

  # query_params: %{
  #  "certification" => "2001",
  #  "delegate" => "10",
  #  "lat" => "48.8668",
  #  "lng" => "2.3405"
  # }
  def track_user_journey_from_params({%Plug.Conn{} = conn, analytic}), do: {:ok, analytic}

  # query_params: %{
  #  "_utf8" => "✓",
  #  "search" => %{
  #    "geolocation_text" => "Paris 1er Arrondissement",
  #    "lat" => "48.86",
  #    "lng" => "2.3413",
  #    "profession" => "Assistanat commercial (Secrétaire commercial / commerciale, ...)",
  #    "rome_code" => "D1401"
  #  }
  # }
  # def track_user_journey_from_params(%Plug.Conn{} = conn), do: conn
  #
  def track_user_journey_from_params({conn, analytic}), do: IO.inspect(conn)
end
