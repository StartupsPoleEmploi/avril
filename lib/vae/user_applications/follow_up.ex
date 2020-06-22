defmodule Vae.UserApplications.FollowUp do
  import Ecto.Query
  import Logger
  alias Vae.{Repo, UserApplication}
  alias VaeWeb.{ApplicationEmail, Mailer}

  def send_admissibility_update_email() do

    query = from(a in UserApplication,
      where: fragment("(?)::timestamp::date", a.submitted_at) == ^Timex.shift(Date.utc_today(), months: -1),
      preload: [:user]
    )
    send_follow_up_emails(query, :monthly_status)
  end

  def send_unsubmitted_raise_email() do

    query = from(a in UserApplication,
      where:
        is_nil(a.submitted_at) and
        fragment("(?)::timestamp::date", a.inserted_at) == ^Timex.shift(Date.utc_today(), days: -3),
      preload: [:user, :certification]
    )
    send_follow_up_emails(query, :user_raise)
  end

  defp send_follow_up_emails(query, email_method) do
    case query
    |> Repo.all()
    |> Enum.map(fn a -> apply(ApplicationEmail, email_method, [a]) end)
    |> Mailer.send() do
      {:ok, emails} -> Logger.info("#{length emails} #{email_method} emails sent")
      {:error, error} -> Logger.warn("Error send #{email_method}: #{inspect(error)}")
    end
  end
end
