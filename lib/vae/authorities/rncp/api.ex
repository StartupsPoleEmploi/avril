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

  def query(params \\ %{}) do
    base_params = %{REPERTOIRE: "RNCP"}
    with(
      query_params <- Map.merge(base_params, params),
      url <- "#{@base_url}?#{URI.encode_query(query_params)}",
      {:ok, response} <- HTTPoison.get(url, @headers),
      {:ok, %{"fiches" => results}} <- response.body |> Jason.decode()
    ) do
      results
    else
      {:error, reason} ->
        Logger.error(fn -> inspect(reason) end)
        []
    end
  end

  def query_all(fiche_fn, page \\ 1) do
    Logger.info("Querying page #{page}")
    case query(%{PAGE: page}) do
      [] -> Logger.info("Finished at page #{page}")
      list when is_list(list) ->
        Enum.map(list, fiche_fn)
        query_all(fiche_fn, page+1)
    end
  end
end