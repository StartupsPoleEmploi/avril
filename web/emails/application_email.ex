defmodule Vae.ApplicationEmail do
  alias Vae.Mailer.Sender.Mailjet
  alias Vae.Email
  alias Vae.Router.Helpers
  alias Vae.Endpoint

  def delegate_submission(application) do
    Email.generic_fields(
      :application_submitted_to_delegate_id,
      application.delegate,
      %{
        application_url:
          Helpers.application_url(Endpoint, :show, application,
            hash: application.delegate_access_hash
          ),
        user_name: application.user.name,
        user_email: application.user.email,
        delegate_name: application.delegate.name,
        certification_name: application.certification.label
      }
    )
  end

  def user_submission_confirmation(application) do
    Email.generic_fields(
      :application_submitted_to_user_id,
      application.user,
      %{
        application_url: Helpers.application_url(Endpoint, :show, application),
        certification_name: application.certification.label,
        delegate_name: application.delegate.name
      }
    )
  end
end
