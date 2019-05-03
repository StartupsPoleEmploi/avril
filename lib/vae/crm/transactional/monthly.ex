defmodule Vae.CRM.Transactional.Monthly do
  alias Vae.Application, as: JsApplication

  alias Vae.Mailer.Email
  alias Vae.CRM.Config

  @sender Application.get_env(:vae, :sender)

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
            application_id: application.id
          },
          template_id: Config.get_monthly_template_id()
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
end
