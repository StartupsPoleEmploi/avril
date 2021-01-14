defmodule Vae.Meetings.FranceVae do
  require Logger

  alias Vae.Meetings.FranceVae.{Config, Connection.Cache, UserRegistration}
  alias Vae.{
    Delegate,
    Meeting,
    UserApplication,
    Repo
  }

  @name FranceVae
  @source :france_vae

  def get_academies() do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Accept", "application/json"}
    ]

    with(
      {:ok, response} <- HTTPoison.get("#{Config.get_base_url()}/academies", headers),
      {:ok, academies} <- response.body |> Jason.decode()
    ) do
      academies
    else
      {:error, reason} ->
        Logger.error(fn -> inspect(reason) end)
        []
    end
  end

  def fetch_all_meetings(academies) do
    Enum.reduce(academies, {:ok, []}, fn %{"id" => academy_id}, {:ok, results} ->
      {:ok, meetings} = fetch_meetings(academy_id)
      {:ok, results ++ meetings}
    end)
  end

  def fetch_meetings(academy_id) do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"}
    ]

    Logger.info("[DAVA] Fetching meetings for academy_id: #{academy_id} in source #{@source}")

    with {:ok, response} <-
           HTTPoison.get("#{Config.get_base_url()}/reunions/#{academy_id}", headers,
             recv_timeout: 15_000
           ),
         {:ok, json} <- response.body |> Jason.decode() do
      json
      |> Map.get("reunions")
      |> case do
        meetings when is_list(meetings) ->
          Logger.info("[DAVA] Retrieved #{length(meetings)} meetings for academy_id: #{academy_id} in source #{@source}")

          meetings
          |> Enum.filter(fn api_meeting ->
            api_meeting
            |> Map.get("cible")
            |> String.trim()
            |> Kernel.in(["CAP au BTS", "Tout public", ""])
          end)
          |> Enum.reduce({:ok, []}, fn api_meeting, {:ok, results} ->
            meeting_data = to_meeting_data(api_meeting, academy_id)

            (Meeting.get_by_meeting_id(@source, meeting_data.meeting_id) || %Meeting{source: "#{@source}"})
            |> Meeting.changeset(%{data: meeting_data})
            |> Repo.insert_or_update()
            |> case do
              {:ok, new_meeting} -> {:ok, [new_meeting | results]}
              {:error, changeset} ->
                Logger.warn("Meeting could not be created:")
                Logger.warn(inspect(changeset))
                Logger.warn("Continuing anyway ...")
                {:ok, results}
            end
          end)
        nil -> {:ok, []}
      end
    else
      {:error, reason} ->
        Logger.error(fn -> inspect(reason) end)
        {:ok, []}
    end
  end

  def register(%Meeting{data: %{meeting_id: meeting_id}}, application) do
    %UserApplication{delegate: %Delegate{academy_id: academy_id}} = application |> Repo.preload(:delegate)
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    user_registration =
      application
      |> UserRegistration.new_meeting_registration(meeting_id)
      |> Jason.encode!()

    with {:ok, response} <-
           HTTPoison.post(
             "#{Config.get_base_url()}/formulaires/#{academy_id}",
             user_registration,
             headers
           ),
         {:ok, body} <- response.body |> Jason.decode() do
      case response.status_code do
        200 -> {:ok, body}
        _ ->
          {:error, body["error"]}
      end
    else
      {:error, msg} = error ->
        error
    end
  end

  def get_token() do
    @name
    |> Macro.underscore()
    |> Cache.get_token()
    |> case do
      {:none, delegate} ->
        headers = [
          {"Content-Type", "application/x-www-form-urlencoded"}
        ]

        with {:ok, response} <-
               HTTPoison.post(
                 Config.get_oauth_url(),
                 "client_id=#{Config.get_client_id()}&client_secret=#{Config.get_client_secret()}&grant_type=client_credentials",
                 headers
               ) do
          response.body
          |> Jason.decode()
          |> case do
            {:ok, body} ->
              with {:ok, access_token} <- Cache.add_token(body, delegate) do
                access_token
              else
                e ->
                  Logger.error(fn -> inspect(e) end)
                  {:error, nil}
              end

            _ ->
              nil
          end
        else
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error(fn -> inspect(reason) end)
            nil
        end

      {:ok, access_token} ->
        access_token
    end
  end

  defp to_meeting_data(params, academy_id) do
    %{
      academy_id: academy_id,
      meeting_id: Integer.to_string(params["id"]),
      place: params["lieu"],
      address: params["addresse"],
      postal_code: params["code_postal"],
      city: params["commune"],
      target: params["cible"],
      start_date: cast_fr_date_and_time_to_naive(params["date"], params["heure_debut"]),
      end_date: cast_fr_date_and_time_to_naive(params["date"], params["heure_fin"]),
      remaining_places: params["nb_places"]
    }
  end

  defp cast_fr_date_and_time_to_naive(date, time) do
    with {:ok, datetime} <- Timex.parse(date, "%d/%m/%Y", :strftime),
         {:ok, formatted_time} <- Time.from_iso8601(time),
         duration <- Timex.Duration.from_time(formatted_time) do
      NaiveDateTime.add(datetime, duration.seconds, :second)
      |> Timex.to_datetime("Europe/Paris")
    else
      # Todo: find a better way
      _ -> nil
    end
  end
end
