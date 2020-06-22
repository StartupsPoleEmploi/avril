defmodule Vae.UserApplications.Config do

  def get_monthly_form_urls() do
    get_monthly_config()
    |> get_form_urls()
  end

  def get_stock_form_urls() do
    get_stock_config()
    |> get_form_urls()
  end

  def get_stock_template_id() do
    get_stock_config()
    |> get_template_id()
  end

  defp get_form_urls(config) do
    config
    |> get_users_config()
    |> Keyword.get(:form_urls)
  end

  defp get_template_id(config) do
    config
    |> get_users_config()
    |> Keyword.get(:template_id)
  end

  defp get_monthly_config() do
    Keyword.get(Application.get_env(:vae, :reminders), :monthly)
  end

  defp get_stock_config() do
    Keyword.get(Application.get_env(:vae, :reminders), :stock)
  end

  defp get_users_config(config) do
    config
    |> Keyword.get(:users)
  end
end
