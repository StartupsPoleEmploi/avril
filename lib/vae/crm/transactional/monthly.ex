defmodule Vae.Crm.Transactional.Monthly do
  alias Vae.{Application, ApplicationEmail, Mailer}

  def execute(date \\ Date.utc_today()) do
    Application.list_from_last_month(date)
    |> Enum.map(&ApplicationEmail.monthly_status(&1))
    |> Mailer.send()
  end
end
