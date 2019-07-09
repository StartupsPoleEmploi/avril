defmodule Vae.Delegates.FranceVae do
  alias Vae.Delegates.Cache
  alias Vae.Delegates.FranceVae.Config

  @name FranceVae

  def get_academies() do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"}
    ]

    {:ok, response} = HTTPoison.get("#{Config.get_base_url()}/academies", headers)
    {:ok, academies} = response.body |> Jason.decode()
    academies
  end

  def get_meetings(academy) do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"}
    ]

    {:ok, response} = HTTPoison.get("#{Config.get_base_url()}/reunions/#{academy}", headers)

    response.body
    |> Jason.decode!()
    |> Map.get("reunions")
    |> Enum.filter(fn meeting ->
      Map.get(meeting, "cible") == "CAP au BTS"
    end)
    |> Enum.map(&to_meeting/1)
  end

  def post_meeting_registration(academy_id, meeting_id, user) do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"}
    ]

    {:ok, response} =
      HTTPoison.post(
        "https://#{Config.get_base_url()}/academie/inscription-rdv/#{academy_id}/#{meeting_id}",
        Vae.Delegates.FranceVae.UserRegistration.from_user(user),
        headers
      )
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

        {:ok, response} =
          HTTPoison.post(
            Config.get_oauth_url(),
            "client_id=#{Config.get_client_id()}&client_secret=#{Config.get_client_secret()}&grant_type=client_credentials",
            headers
          )

        response.body
        |> Jason.decode()
        |> case do
          {:ok, body} ->
            with {:ok, access_token} <- Cache.add_token(body, delegate) do
              access_token
            else
              e ->
                Log.error(fn -> inspect(e) end)
                {:error, nil}
            end

          _ ->
            nil
        end

      {:ok, access_token} ->
        access_token
    end
  end

  defp to_meeting(params) do
    %{
      academy_id: params["academy_id"],
      meeting_id: params["meeting_id"],
      place: params["lieu"],
      address: params["addresse"],
      target: params["cible"],
      start_date: cast_fr_date_and_time_to_naive(params["date"], params["heure_debut"]),
      end_date: cast_fr_date_and_time_to_naive(params["date"], params["heure_fin"])
    }
  end

  defp cast_fr_date_and_time_to_naive(date, time) do
    with {:ok, datetime} <- Timex.parse(date, "%d/%m/%Y", :strftime),
         {:ok, formatted_time} <- Time.from_iso8601(time),
         duration <- Timex.Duration.from_time(formatted_time) do
      NaiveDateTime.add(datetime, duration.seconds, :second)
    else
      # Todo: find a better way
      _ -> nil
    end
  end
end
