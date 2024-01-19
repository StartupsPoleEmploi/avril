defmodule Vae.Authorities.Rncp.Api do
  require Logger

  @api_config Application.get_env(:vae, :rncp)
  @base_url @api_config[:url]
  @api_key @api_config[:api_key]
  @headers ["X-Gravitee-Api-Key": @api_key, "Content-Type": "application/json"]
  @timeout 10_000

  def get(rncp_id) do
    query(%{NUMERO_FICHE: "RNCP#{rncp_id}"})
    |> Enum.find(fn fiche -> fiche["NUMERO_FICHE"] == "RNCP#{rncp_id}" end)
  end

  def query(params \\ %{}) do
    base_params = %{REPERTOIRE: "RNCP"}
    with(
      query_params <- Map.merge(base_params, params),
      url <- "#{@base_url}?#{URI.encode_query(query_params)}",
      {:ok, response} <- HTTPoison.get(url, @headers, [recv_timeout: @timeout]),
      {:ok, json} <- response.body |> Jason.decode()
    ) do
      case json do
        %{"fiches" => results} -> results
        %{"message" => message} ->
          Logger.info("Message: #{message}")
          []
        %{"globalErrors" => errors} ->
          Logger.error(fn -> inspect(errors) end)
          []
      end
    else
      {:error, reason} ->
        Logger.error(fn -> inspect(reason) end)
        nil
    end
  end

  def query_all(fiche_fn, page \\ 1) do
    case query(%{PAGE: page}) do
      nil -> Logger.info("Stopped at page #{page}")
      [] -> Logger.info("Finished at page #{page}")
      list when is_list(list) ->
        Logger.info("Continuing at page #{page}")
        Enum.map(list, fn fiche ->
          # Logger.info("#################################")
          # Logger.info("# Page #{page}: Fiche #{fiche["NUMERO_FICHE"]} #")
          # Logger.info("#################################")
          fiche_fn.(fiche)
        end)
        query_all(fiche_fn, page+1)
    end
  end
end