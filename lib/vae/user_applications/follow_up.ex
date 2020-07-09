defmodule Vae.UserApplications.FollowUp do
  import Ecto.Query
  require Logger
  alias Vae.{Delegate, Repo, UserApplication}
  alias VaeWeb.{ApplicationEmail, DelegateEmail, Mailer}

  def send_admissibility_update_email() do
    from(a in UserApplication,
      where: fragment("(?)::timestamp::date", a.submitted_at) == ^Timex.shift(Date.utc_today(), months: -1),
      preload: [:user]
    )
    |> Repo.all()
    |> send_follow_up_emails(ApplicationEmail, :monthly_status)
  end

  def send_unsubmitted_raise_email() do
    from(a in UserApplication,
      where:
        is_nil(a.submitted_at) and
        fragment("(?)::timestamp::date", a.inserted_at) == ^Timex.shift(Date.utc_today(), days: -3),
      preload: [:user, :certification]
    )
    |> Repo.all()
    |> send_follow_up_emails(ApplicationEmail, :user_raise)
  end

  def send_delegate_recap_email() do
    from(d in Delegate,
      join: s in assoc(d, :recent_applications),
      preload: :recent_applications
    )
    |> Repo.all()
    |> Enum.filter(fn d -> length(d.recent_applications) >= 3 end)
    |> Enum.uniq()
    |> send_follow_up_emails(DelegateEmail, :applications_raise)
  end

  defp send_follow_up_emails(models, email_module, email_method) do
    case models
    |> Enum.map(fn model -> apply(email_module, email_method, [model]) end)
    |> Mailer.send() do
      {:ok, emails} -> Logger.info("#{length emails} #{email_method} emails sent")
      {:error, error} -> Logger.warn("Error send #{email_method}: #{inspect(error)}")
    end
  end
end
