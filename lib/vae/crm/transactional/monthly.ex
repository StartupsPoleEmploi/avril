defmodule Vae.CRM.Transactional.Monthly do
  alias Vae.Application, as: JsApplication

  alias Vae.Mailer.Email

  @sender Application.get_env(:vae, :sender)
  @reminders Application.get_env(:vae, :reminders)

  def execute(date \\ Date.utc_today()) do
    get_applications_from(date)
    |> build_records()
    |> build_emails()
    |> send_email()
  end

  def get_applications_from(date), do: JsApplication.list_from_last_month(date)

  def build_records(applications) do
    applications
    |> Enum.reduce(Keyword.new(), fn application, acc ->
      Keyword.put(acc, String.to_atom(UUID.uuid5(nil, application.user.email)), application)
    end)
  end

  def build_emails(applications) do
    applications
    |> Enum.reduce([], fn {custom_id, application}, acc ->
      [
        %Email{
          custom_id: Atom.to_string(custom_id),
          job_seeker: application.user.job_seeker,
          vars: %{
            form_url: define_form_url_from_application(application)
          },
          template_id: get_template_id()
        }
        | acc
      ]
    end)
  end

  def send_email(emails) do
    emails
    |> Enum.reduce([], fn email, acc ->
      case @sender.send(email) do
        %Email{state: :success} -> acc
        _ -> [email | acc]
      end
    end)
  end

  def define_form_url_from_application(application) do
    certifiers = application.delegate.certifiers
    get_form_url_from_certifier_id(hd(certifiers).id)
  end

  defp get_template_id() do
    get_users_config()
    |> Keyword.get(:template_id)
  end

  defp get_monthly_config() do
    Keyword.get(@reminders, :monthly)
  end

  defp get_users_config() do
    get_monthly_config()
    |> Keyword.get(:users)
  end

  defp get_form_urls() do
    get_users_config()
    |> Keyword.get(:form_urls)
  end

  defp get_form_url_from_certifier_id(certifier_id) do
    with form_urls <- get_form_urls(),
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
    get_in(get_form_urls(), [:certifiers, :other, :url])
  end
end
