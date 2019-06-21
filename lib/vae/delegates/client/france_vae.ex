defmodule Vae.Delegates.Client.FranceVae do
  alias Vae.Delegates.Cache

  @name FranceVae

  def get_academies() do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"}
    ]

    {:ok, response} = HTTPoison.get("https://www.francevae.fr/api/academies", headers)
  end

  def get_meeting_informations(academy) do
    token = get_token()

    headers = [
      {"Authorization", "Bearer #{token}"}
    ]

    {:ok, response} = HTTPoison.get("https://www.francevae.fr/api/reunions/1", headers)
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
            "https://www.francevae.fr/api/oauth/v2/token",
            "client_id=#{System.get_env("FRANCE_VAE_CLIENT_ID")}&client_secret=#{
              System.get_env("FRANCE_VAE_CLIENT_SECRET")
            }&grant_type=client_credentials",
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
end
