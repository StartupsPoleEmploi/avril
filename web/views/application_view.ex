defmodule Vae.ApplicationView do
  use Vae.Web, :view
  use Scrivener.HTML

  def format_meeting_date(meeting), do: Timex.format!(meeting.start_date, "%d/%m/%Y", :strftime)
  def format_meeting_hour(meeting), do: Timex.format!(meeting.start_date, "%Hh%M", :strftime)
end
