defmodule VaeWeb.ApplicationEmail do
  require Logger
  alias VaeWeb.Mailer

  @date_format "%d/%m/%Y à %H:%M"

  alias Vae.{Certification, Delegate, Repo, User, UserApplication, URI}
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
        username: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        has_booklet: application.booklet_1 && application.booklet_1.completed_at,
        date_format: @date_format,
        footer_note: :delegate
      }
    )
  end

  def delegate_cancelled_application(application) do
    application = Repo.preload(application, [:user, :delegate, :certification, :meeting])

    Mailer.build_email(
      "application/delegate_cancelled_application.html",
      :avril,
      application.delegate,
      %{
        username: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        meeting: application.meeting,
        date_format: @date_format,
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
        username: User.fullname(application.user),
        is_france_vae: application.delegate && application.delegate.academy_id,
        is_afpa: application.delegate && Delegate.is_afpa?(application.delegate),
        certification_name: Certification.name(application.certification),
        delegate_name: application.delegate && application.delegate.name,
        delegate_person_name: application.delegate && application.delegate.person_name,
        delegate_phone_number: application.delegate && application.delegate.telephone,
        delegate_email: application.delegate && application.delegate.email,
        date_format: @date_format,
        image_url: URI.static_url(endpoint, "/images/group.png"),
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
        username: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        delegate_person_name: application.delegate.person_name,
        delegate_phone_number: application.delegate.telephone,
        delegate_email: application.delegate.email,
        delegate_website: application.delegate.website,
        image_url: URI.static_url(endpoint, "/images/group.png"),
        footer_note: :inscrit_avril
      }
    )
  end

  def user_meeting_confirmation(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :delegate, :certification, :meeting])
    Mailer.build_email(
      "application/meeting_confirmation.html",
      :avril,
      application.user,
      %{
        url: User.profile_url(endpoint, "/mes-rendez-vous"),
        meeting: application.meeting.data,
        username: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
        delegate_phone_number: application.delegate.telephone,
        image_url: URI.static_url(endpoint, "/images/group.png"),
        date_format: @date_format,
        footer_note: :inscrit_avril
      }
    )
  end

  def user_meeting_cancelled(application, endpoint \\ URI.endpoint()) do
    %UserApplication{meeting: meeting} = application |> Repo.preload(:meeting)
    if not is_nil(meeting) do
      Mailer.build_email(
        "application/user_meeting_cancelled.html",
        :avril,
        application.user,
        %{
          url: User.profile_url(endpoint, application),
          meeting: meeting.data,
          source: Vae.Meeting.source_string(meeting.source),
          username: User.fullname(application.user),
          date_format: @date_format,
          footer_note: :inscrit_avril
        }
      )
    else
      Logger.warn("Application #{application.id} has no meeting")
    end
  end

  def user_raise(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :certification])
    finish_booklet_todo = application.booklet_1 && application.booklet_1.inserted_at
    certification_name = Certification.name(application.certification)
    username = User.fullname(application.user)

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

  def wrong_educ_nat(application, endpoint \\ URI.endpoint()) do
    application = Repo.preload(application, [:user, :delegate, :certification])

    Mailer.build_email(
      "application/wrong_educ_nat.html",
      :avril,
      application.user,
      %{
        url:
          Routes.user_application_url(endpoint, :show, application),
        username: User.fullname(application.user),
        certification_name: Certification.name(application.certification),
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
        can_unsubscribe: true,
        footer_note: :mise_en_relation
      }
    )
  end
end
