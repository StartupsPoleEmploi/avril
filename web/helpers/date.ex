defmodule Vae.Date do
  def format(date_string) do
    case Date.from_iso8601("#{String.slice(date_string, 0..3)}-#{String.slice(date_string, 4..5)}-#{String.slice(date_string, 6..7)}") do
      {:ok, datetime} -> datetime
      {:error, _} -> nil
    end
  end
end