defmodule VaeWeb.ApplicationEmail do
  alias VaeWeb.Mailer

  @date_format "%d/%m/%Y à %H:%M"

  alias Vae.{Account, Certification, Delegate, Repo, User, URI}
  alias VaeWeb.Router.Helpers, as: Routes

  def delegate_submission(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :delegate, :certification])

    Mailer.build_email(
      "application/delegate_submission.html",
      :avril,
      application.delegate,
      %{
        url:
          Routes.user_application_url(endpoint, :show, application,
            hash: application.delegate_access_hash
          ),
        username: Account.fullname(application.user),
        certification_name: Certification.name(application.certification),
        date_format: @date_format,
        meeting: application.meeting,
        footer_note: :delegate
      }
    )
  end

  def user_submission_confirmation(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :delegate, :certification])

    Mailer.build_email(
      "application/user_submission_confirmation.html",
      :avril,
      application.user,
      %{
        url: User.profile_url(endpoint, application),
        username: Account.fullname(application.user),
        meeting: application.meeting,
        date_format: "%d/%m/%Y à %H:%M",
        is_france_vae: application.delegate && application.delegate.academy_id,
        is_afpa: application.delegate && Delegate.is_afpa?(application.delegate),
        certification_name: Certification.name(application.certification),
        delegate_name: application.delegate && application.delegate.name,
        delegate_person_name: application.delegate && application.delegate.person_name,
        delegate_phone_number: application.delegate && application.delegate.telephone,
        delegate_email: application.delegate && application.delegate.email,
        date_format: @date_format,
        image_url: Routes.static_url(VaeWeb.Endpoint, "/images/group.png"),
        text_center: true,
        footer_note: :inscrit_avril
      }
    )
  end

  def asp_user_submission_confirmation(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :delegate])

    Mailer.build_email(
      "application/asp_user_submission_confirmation.html",
      :avril,
      application.user,
      %{
        url: User.profile_url(endpoint, application),
        username: Account.fullname(application.user),
        meeting: application.meeting,
        certification_name: Certification.name(application.certification),
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        delegate_website: application.delegate.website,
        image_url: Routes.static_url(VaeWeb.Endpoint, "/images/group.png"),
        footer_note: :inscrit_avril
      }
    )
  end

  def user_meeting_confirmation(application, endpoint \\ URI.endpoint()) do
    Mailer.build_email(
      "application/meeting_confirmation.html",
      :avril,
      application.user,
      %{
        url: User.profile_url(endpoint, "/mes-rendez-vous"),
        meeting: application.meeting,
        username: Account.fullname(application.user),
        certification_name: Certification.name(application.certification),
        image_url: Routes.static_url(VaeWeb.Endpoint, "/images/group.png"),
        date_format: @date_format,
        footer_note: :inscrit_avril
      }
    )
  end

  def user_raise(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :certification])
    finish_booklet_todo = application.booklet_1 && application.booklet_1.inserted_at
    certification_name = Certification.name(application.certification)
    username = Account.fullname(application.user)

    Mailer.build_email(
      "application/user_raise.html",
      :avril,
      application.user,
      %{
        application_url: User.profile_url(endpoint, application),
        username: username,
        certification_name: certification_name,
        finish_booklet_todo: finish_booklet_todo,
        footer_note: :inscrit_avril
      }
    )
  end

  def monthly_status(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user])

    Mailer.build_email(
      "application/monthly_status.html",
      :avril,
      application.user,
      %{
        admissible_url: Routes.user_application_url(endpoint, :admissible, application),
        inadmissible_url: Routes.user_application_url(endpoint, :inadmissible, application),
        text_center: true,
        footer_note: :mise_en_relation
      }
    )
  end
end
