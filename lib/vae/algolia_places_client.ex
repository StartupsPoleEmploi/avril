defmodule Vae.PlacesClient.Algolia do
  @behaviour Vae.PlacesClient

  @url_places "https://status.algolia.com/1/usage/total_read_operations/period/month/places"

  def get({credentials, index}) do
    {index, do_get(credentials)}
  end

  defp do_get({app_id, api_key}) do
    headers = ["X-Algolia-Application-Id": app_id, "X-Algolia-API-Key": api_key]
    %Date{month: current_month} = Date.utc_today

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(@url_places, headers),
         {:ok, json} <- body |> Poison.decode() do
      json
      |> Map.get("total_read_operations")
      |> Enum.filter(&is_same_month?(&1, current_month))
      |> Enum.reduce(0, &add(&1, &2))
    end
  end

  defp is_same_month?(%{"t" => t, "v" => _v}, current_month) do
    {:ok, dt} = DateTime.from_unix(t, :millisecond)
    current_month == dt.month
  end

  defp add(%{"t" => _t, "v" => v}, acc), do: acc + v
end
