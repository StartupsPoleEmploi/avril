defmodule Vae.ApplicationEmail do
  alias Vae.Mailer

  alias Vae.{Certification, Email, Endpoint, Repo, User}
  alias Vae.Router.Helpers

  def delegate_submission(application) do
    application = Repo.preload(application, [:user, :delegate])
    Mailer.send_email(
      "application/delegate_submission.html",
      :avril,
      application.delegate,
      %{
        url:
          Helpers.application_url(Endpoint, :show, application,
            hash: application.delegate_access_hash
          ),
        user_name: User.fullname(application.user),
        subject: "#{User.fullname(application.user)} souhaite faire une VAE: A vous de le/la recontacter !"
      }
    )
  end

  # def delegate_submission(application) do
  #   application = Repo.preload(application, [:user, :delegate, :certification])
  #   Email.generic_fields(
  #     :application_submitted_to_delegate_id,
  #     application.delegate,
  #     %{
  #       application_url:
  #         Helpers.application_url(Endpoint, :show, application,
  #           hash: application.delegate_access_hash
  #         ),
  #       user_name: User.fullname(application.user),
  #       user_email: application.user.email,
  #       delegate_name: application.delegate.name,
  #       certification_name: Certification.name(application.certification)
  #     }
  #   )
  # end

  def user_submission_confirmation(application) do
    application = Repo.preload(application, [:user, :delegate])
    Mailer.send_email(
      "application/user_submission_confirmation.html",
      :avril,
      application.user,
      %{
        url: Helpers.application_url(Endpoint, :show, application),
        user_name: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        delegate_name: application.delegate.name,
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        subject: "#{application.user} souhaite faire une VAE: A vous de le/la recontacter !"
      }
    )
  end

  # def user_submission_confirmation(application) do
    # application = Repo.preload(application, [:user, :delegate, :certification])
  #   Email.generic_fields(
  #     :application_submitted_to_user_id,
  #     application.user,
  #     %{
  #       user_name: User.fullname(application.user),
  #       application_url: Helpers.application_url(Endpoint, :show, application),
  #       certification_name: Certification.name(application.certification),
  #       delegate_name: application.delegate.name,
  #       delegate_person_name: application.delegate.person_name,
  #       delegate_phone_number: application.delegate.telephone,
  #       delegate_email: application.delegate.email
  #     }
  #   )
  # end
end
