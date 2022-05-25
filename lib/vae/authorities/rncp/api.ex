defmodule Vae.Authorities.Rncp.Api do
  require Logger

  @api_config Application.get_env(:vae, :rncp)
  @base_url @api_config[:url]
  @api_key @api_config[:api_key]
  @headers ["X-Gravitee-Api-Key": @api_key, "Content-Type": "application/json"]

  def get(rncp_id) do
    query(%{NUMERO_FICHE: "RNCP#{rncp_id}"})
    |> List.first()
  end

  def query(params = %{}) do
    with(
      {:ok, response} <- HTTPoison.get("#{@base_url}?#{URI.encode_query(params)}", @headers),
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