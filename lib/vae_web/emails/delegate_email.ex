defmodule VaeWeb.DelegateEmail do
  import Ecto.Query
  alias VaeWeb.Mailer

  alias Vae.{Account, Certification, Identity, Repo, User, UserApplication}
  alias VaeWeb.Endpoint
  alias VaeWeb.Router.Helpers, as: Routes

  def applications_raise(delegate, endpoint \\ Endpoint) do
    delegate = Repo.preload(delegate, [recent_applications: [:certification, :user]])
    Mailer.build_email(
      "delegate/applications_raise.html",
      :avril,
      delegate,
      %{
        delegate: delegate,
        applications: delegate.recent_applications,
        label: fn a -> "#{Identity.fullname(a.user.identity)} : #{Certification.name(a.certification)}" end,
        link: fn a -> Routes.user_application_url(endpoint, :show, a, hash: a.delegate_access_hash) end,
        footer_note: :delegate
      }
    )
  end
end
