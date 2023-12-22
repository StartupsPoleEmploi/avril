defmodule VaeWeb.DelegateEmail do
  import Ecto
  # import Ecto.Changeset
  import Ecto.Query

  alias VaeWeb.Mailer

  alias Vae.{Certification, Certifier, Delegate, User, UserApplication, Repo, URI}
  alias VaeWeb.Router.Helpers, as: Routes

  @afpa_cc System.get_env("AFPA_CC_ADDRESS")
  @date_format "%d/%m/%Y"

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

  def delegate_access_info(delegate, _endpoint \\ URI.endpoint()) do
    Mailer.build_email(
      "delegate/delegate_access_info.html",
      :avril,
      delegate,
      %{
        delegate_name: delegate.name,
        footer_note: :delegate,
      }
    )
  end

  def inform_optional_booklet(delegate, _endpoint \\ URI.endpoint()) do
    Mailer.build_email(
      "delegate/inform_optional_booklet.html",
      :avril,
      delegate,
      %{
        delegate_name: delegate.name,
        footer_note: :delegate,
      }
    )
  end

  def goodbye(delegate, _endpoint \\ URI.endpoint()) do
    delegate = Repo.preload(delegate, :certifiers)

    start_date =
      from(a in assoc(delegate, :applications), order_by: fragment("?::date ASC", a.inserted_at), limit: 1) |> Repo.one() |> Map.get(:inserted_at) || ~D[2019-04-16]

    submitted_application_count = delegate |> assoc(:applications) |> where([a], not is_nil(a.submitted_at)) |> Repo.aggregate(:count, :id)

    popular_certifications = from(
      c in Certification,
      left_join: u in UserApplication, where: u.delegate_id == ^delegate.id and u.certification_id == c.id and not is_nil(u.submitted_at),
      group_by: c.id,
      order_by: [desc: count(u.id)],
      limit: 5
    )
    |> Repo.all()

    popular_certifications_list = Enum.map(popular_certifications, fn %Certification{} = certification ->
      "- #{Certification.name(certification)} : #{Vae.String.inflect(delegate_certification_application_count(delegate, certification), "candidature")}\n"
    end) |> Enum.join("\n")

    certifiers_application_count = Enum.map(delegate.certifiers, fn certifier ->
      "#{Vae.String.inflect(certifier_application_count(certifier), "candidature")} pour le certificateur #{certifier.name}"
    end) |> Enum.join(", ")

    Mailer.build_email(
      "delegate/goodbye.html",
      :avril,
      delegate,
      %{
        delegate_name: delegate.name,
        start_date: start_date,
        submitted_application_count: submitted_application_count,
        popular_certifications_list: popular_certifications_list,
        certifiers_application_count: certifiers_application_count,
        date_format: @date_format,
        footer_note: :delegate,
      }
    )

  end

  def delegate_certification_application_count(delegate, certification) do
    from(
      u in UserApplication,
      where: u.delegate_id == ^delegate.id and u.certification_id == ^certification.id and not is_nil(u.submitted_at)
    ) |> Repo.aggregate(:count, :id)
  end

  def certifier_application_count(certifier) do
    certifier |> assoc(:applications) |> where([a], not is_nil(a.submitted_at)) |> Repo.aggregate(:count, :id)
  end

  def send_all_delegates() do
    from(d in Delegate, where: d.is_active, limit: 10)
    |> Repo.all()
    |> Enum.map(fn delegate ->
      IO.inspect(delegate)
      |> VaeWeb.DelegateEmail.goodbye()
      |> VaeWeb.Mailer.send()
    end)
  end

end
