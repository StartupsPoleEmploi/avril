defmodule VaeWeb.ApplicationEmail do
  alias VaeWeb.Mailer

  alias Vae.{Account, Certification, Repo, User}
  alias VaeWeb.Endpoint
  alias VaeWeb.Router.Helpers, as: Routes

  def delegate_submission(application) do
    application = Repo.preload(application, [:user, :delegate, :certification])

    Mailer.build_email(
      "application/delegate_submission.html",
      :avril,
      application.delegate,
      %{
        url:
          Routes.user_application_url(Endpoint, :show, application,
            hash: application.delegate_access_hash
          ),
        username: Account.fullname(application.user),
        certification_name: Certification.name(application.certification),
        date_format: "%d/%m/%Y à %H:%M",
        meeting: application.meeting
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
        url: User.profile_url(Endpoint, application),
        username: Account.fullname(application.user),
        meeting: application.meeting,
        date_format: "%d/%m/%Y à %H:%M",
        is_france_vae: not is_nil(application.delegate.academy_id),
        certification_name: Certification.name(application.certification),
        delegate_name: application.delegate.name,
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
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
        url: User.profile_url(Endpoint, application),
        username: Account.fullname(application.user),
        certification_name: Certification.name(application.certification),
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        delegate_website: application.delegate.website,
        image_url: Routes.static_url(Endpoint, "/images/group.png"),
        footer_note: :inscrit_avril
      }
    )
  end

  def user_raise(application, path \\ Endpoint) do
    application = Repo.preload(application, [:user, :certification])
    finish_booklet_todo = not is_nil(application.booklet_1.inserted_at)
    certification_name = Certification.name(application.certification)
    username = Account.fullname(application.user)

    Mailer.build_email(
      "application/user_raise.html",
      :avril,
      application.user,
      %{
        application_url: User.profile_url(path, application),
        # booklet_url: Vae.UserApplication.booklet_url(path, application),
        username: username,
        certification_name: certification_name,
        finish_booklet_todo: finish_booklet_todo,
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
