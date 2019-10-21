defmodule Vae.ApplicationEmail do
  alias Vae.Mailer

  alias Vae.{Certification, Endpoint, Repo, User}
  alias Vae.Router.Helpers, as: Routes

  def delegate_submission(application) do
    application = Repo.preload(application, [:user, :delegate, :certification])
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
        certification_name: Certification.name(application.certification),
        date_format: "%d/%m/%Y à %H:%M",
        meeting: application.meeting,
        subject: "#{User.fullname(application.user)} souhaite faire une VAE: A vous de le/la recontacter !"
      }
    )
  end

  def user_submission_confirmation(application) do
    application = Repo.preload(application, [:user, :delegate, :certification])
    Mailer.build_email(
      "application/user_submission_confirmation.html",
      :avril,
      application.user,
      %{
        url: Routes.application_url(Endpoint, :show, application),
        user_name: User.fullname(application.user),
        meeting: application.meeting,
        date_format: "%d/%m/%Y à %H:%M",
        is_france_vae: not is_nil(application.delegate.academy_id),
        certification_name: Certification.name(application.certification),
        delegate_name: application.delegate.name,
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        subject: "#{User.fullname(application.user)}, voici comment obtenir votre #{Certification.name(application.certification)}",
        image_url: Routes.static_url(Endpoint, "/images/group.png"),
        footer_note: :inscrit_avril
      }
    )
  end

  def asp_user_submission_confirmation(application) do
    application = Repo.preload(application, [:user, :delegate])
    Mailer.build_email(
      "application/asp_user_submission_confirmation.html",
      :avril,
      application.user,
      %{
        url: Routes.application_url(Endpoint, :show, application),
        user_name: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        delegate_website: application.delegate.website,
        subject: "#{User.fullname(application.user)}, voici comment obtenir votre #{Certification.name(application.certification)}",
        image_url: Routes.static_url(Endpoint, "/images/group.png"),
        footer_note: :inscrit_avril
      }
    )
  end

  def monthly_status(application) do
    application = Repo.preload(application, [:user])
    Mailer.build_email(
      Vae.Crm.Config.get_monthly_template_id(),
      :avril,
      application.user,
      %{
        custom_id: UUID.uuid5(nil, application.user.email),
        application_id: application.id,
        footer_note: :inscrit_avril
      }
    )
  end

end
