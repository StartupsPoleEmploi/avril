defmodule Vae.Crm.Transactional.Monthly do
  alias VaeWeb.Mailer
  alias VaeWeb.ApplicationEmail
  alias Vae.UserApplication

  def execute(date \\ Date.utc_today()) do
    UserApplication.list_from_last_month(date)
    |> Enum.map(&ApplicationEmail.monthly_status(&1))
    |> Mailer.send()
  end
end
