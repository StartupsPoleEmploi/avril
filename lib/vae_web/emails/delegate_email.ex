defmodule VaeWeb.DelegateEmail do
  alias VaeWeb.Mailer

  alias Vae.{Certification, Identity, Repo, URI}
  alias VaeWeb.Router.Helpers, as: Routes

  def applications_raise(delegate, endpoint \\ URI.endpoint()) do
    delegate = Repo.preload(delegate, recent_applications: [:certification, :user])
    Mailer.build_email(
      "delegate/applications_raise.html",
      :avril,
      delegate,
      %{
        delegate: delegate,
        applications: delegate.recent_applications,
        label: fn a -> "#{Identity.fullname(a.user.identity)} : #{Certification.name(a.certification)}" end,
        link: fn a -> Routes.user_application_url(endpoint, :show, a, [delegate_hash: a.delegate_access_hash]) end,
        footer_note: :delegate
      }
    )
  end
end
