defmodule Vae.Date do
  @moduledoc """
  `Date` method helpers
  """
  def format(nil), do: nil

  def format(date_string) do
    result =
      if Regex.match?(~r/^\d{8}$/, date_string) do
        Date.from_iso8601(
          "#{String.slice(date_string, 0..3)}-#{String.slice(date_string, 4..5)}-#{
            String.slice(date_string, 6..7)
          }"
        )
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

  def format_iso(nil), do: nil
  def format_iso(date), do: Timex.format!(date, "%d/%m/%Y", :strftime)

  def workdays_between(start_date, end_date \\ nil) do
    end_date = end_date || Date.utc_today()
    end_date = if Timex.compare(end_date, start_date, :day) < 1, do: start_date, else: end_date

    Timex.Interval.new(from: start_date, until: Date.add(end_date, 1))
    |> Enum.filter(&(!weekend?(&1)))
    |> Enum.count()
    |> max(1)
  end

  def weekend?(date) do
    Date.day_of_week(date) > 5
  end

  def get_previous_month(date) do
    Timex.shift(date, months: -1)
  end

  def last_monday() do
    Date.utc_today()
    |> Timex.beginning_of_week()
  end
end
