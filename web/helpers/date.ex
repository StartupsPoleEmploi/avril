defmodule Vae.Date do
  @moduledoc """
  `Date` method helpers
  """
  def format(nil), do: nil

  def format(date_string) do
    result = if Regex.match?(~r/^\d{8}$/, date_string) do
      Date.from_iso8601("#{String.slice(date_string, 0..3)}-#{String.slice(date_string, 4..5)}-#{String.slice(date_string, 6..7)}")
    else
      DateTime.from_iso8601(date_string)
    end
    case result do
      {:ok, datetime, _} -> datetime
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  def format_for_unique_key(date) do
    case Timex.format(date, "{YYYY}{0M}{0D}") do
      {:ok, str} -> str
      {:error, _error_msg} -> "unknown"
    end
  end
end