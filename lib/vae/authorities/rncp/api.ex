defmodule Vae.Authorities.Rncp.Api do
  require Logger

  @base_url "https://api.francecompetences.fr/referentiels/v1/fiches"
  @api_key "b70405cf-cd36-4df2-a666-987236c57050"
  @headers ["X-Gravitee-Api-Key": @api_key, "Content-Type": "application/json"]

  def get(rncp_id) do
    query(%{NUMERO_FICHE: "RNCP#{rncp_id}"})
    |> List.first()
  end

  def query(params = %{}) do
    base_params = %{
      STATUT: "ACTIF"
    }
    with(
      {:ok, response} <- HTTPoison.get("#{@base_url}?#{URI.encode_query(Map.merge(base_params, params))}", @headers),
      {:ok, %{"fiches" => results}} <- response.body |> Jason.decode()
    ) do
      results
    else
      {:error, reason} ->
        Logger.error(fn -> inspect(reason) end)
        []
    end
  end
end