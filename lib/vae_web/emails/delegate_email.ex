defmodule VaeWeb.DelegateEmail do
  alias VaeWeb.Mailer

  alias Vae.{Certification, User, Repo, URI}
  alias VaeWeb.Router.Helpers, as: Routes

  @afpa_cc System.get_env("AFPA_CC_ADDRESS")

  def applications_raise(delegate, options \\ %{}, endpoint \\ URI.endpoint()) do
    delegate = Repo.preload(delegate, recent_applications: [:certification, :user])
    Mailer.build_email(
      "delegate/applications_raise.html",
      :avril,
      delegate,
      Map.merge(%{
        delegate: delegate,
        applications: delegate.recent_applications,
        label: fn a -> "#{User.fullname(a.user)} : #{Certification.name(a.certification)}" end,
        link: fn a -> Routes.user_application_url(endpoint, :show, a, [delegate_hash: a.delegate_access_hash]) end,
        footer_note: :delegate,
        cc: (if String.starts_with?(delegate.slug, "afpa") && @afpa_cc, do: @afpa_cc)
      }, options)
    )
  end
end
