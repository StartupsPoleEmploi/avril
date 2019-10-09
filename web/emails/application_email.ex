defmodule Vae.ApplicationEmail do
  alias Vae.Mailer

  alias Vae.{Certification, Endpoint, Repo, User}
  alias Vae.Router.Helpers, as: Routes

  def delegate_submission(application) do
    application = Repo.preload(application, [:user, :delegate])
    Mailer.build_email(
      "application/delegate_submission.html",
      :avril,
      application.delegate,
      %{
        url:
          Routes.application_url(Endpoint, :show, application,
            hash: application.delegate_access_hash
          ),
        user_name: User.fullname(application.user),
        subject: "#{User.fullname(application.user)} souhaite faire une VAE: A vous de le/la recontacter !"
      }
    )
  end

  def user_submission_confirmation(application) do
    application = Repo.preload(application, [:user, :delegate])
    Mailer.build_email(
      "application/user_submission_confirmation.html",
      :avril,
      application.user,
      %{
        url: Routes.application_url(Endpoint, :show, application),
        user_name: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        delegate_name: application.delegate.name,
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        subject: "Félicitations #{User.fullname(application.user)} pour votre projet VAE: découvrez la prochaine étape"
      }
    )
  end
end
