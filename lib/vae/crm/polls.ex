defmodule Vae.CRM.Polls do
  alias Vae.CRM.Config

  def define_form_url_from_application(application) do
    certifiers = application.delegate.certifiers
    get_form_url_from_certifier_id(hd(certifiers).id)
  end

  defp get_form_url_from_certifier_id(certifier_id) do
    with form_urls <- Config.get_monthly_form_urls(),
         certifiers_form_url <- Keyword.get(form_urls, :certifiers) do
      Enum.reduce(
        certifiers_form_url,
        get_default_form_url(),
        fn {_certifier_name, %{ids: ids, url: url}}, acc ->
          if certifier_id in ids do
            url
          else
            acc
          end
        end
      )
    end
  end

  defp get_default_form_url() do
    get_in(Config.get_monthly_form_urls(), [:certifiers, :other, :url])
  end
end
