defmodule Vae.ApplicationEmail do

  alias Vae.{Email, Endpoint, Repo, User}
  alias Vae.Router.Helpers

  def delegate_submission(application) do
    application = Repo.preload(application, [:user, :delegate, :certification])
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
    application = Repo.preload(application, [:user, :delegate, :certification])
    Email.generic_fields(
      :application_submitted_to_user_id,
      application.user,
      %{
        user_name: User.fullname(application.user),
        application_url: Helpers.application_url(Endpoint, :show, application),
        certification_name: application.certification.label,
        delegate_name: application.delegate.name,
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.phone_number,
        delegate_email: application.delegate.email
      }
    )
  end
end
