defmodule Vae.Suggest do
  require Logger

  @lbb_suggest_url "https://labonneboite.pole-emploi.fr/suggest_job_labels?term="

  def get_suggest(params) do
    with params <- params |> clean,
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- params |> get,
         {:ok, json} <- body |> Poison.decode() do
      {:ok, json}
    else
      {:ok, %HTTPoison.Response{status_code: status_code, request_url: request_url}} ->
        {:error, "Cannot retrieve rome <#{status_code}>from #{request_url}"}

      {:error, {cause, _char, _line}} ->
        {:error, cause}

      {:error, _} ->
        {:error, "Cannot retrieve rome"}

      msg ->
        Logger.error(msg)
    end
  end

  defp clean(params) do
    # Fix quoting search problem
    params
    |> String.replace("'", " ")
    |> URI.encode_www_form()
  end

  defp get(params) do
    HTTPoison.get(@lbb_suggest_url <> params)
  end
end
