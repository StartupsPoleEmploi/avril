defmodule Vae.CRM.Transactional.Monthly do
  alias Vae.JobSeeker
  alias Vae.Mailer.Email

  @sender Application.get_env(:vae, :sender)

  def execute() do
    get_job_seekers_from(Date.utc_today())
    |> build_records()
    |> build_emails()
    |> send_email()

    # |> handle_errors()
  end

  def get_job_seekers_from(date) do
    JobSeeker.list_from_last_month(date)
  end

  def build_records(job_seekers) do
    job_seekers.rows
    |> Enum.map(&Vae.Repo.load(JobSeeker, {job_seekers.columns, &1}))
    |> Enum.reduce(%{}, fn js, acc ->
      js.events
      |> filter_by_date(Date.utc_today())
      |> filter_by_empty_event_payload()
      |> filter_by_delegate_contact()
      |> case do
        [] ->
          acc

        events ->
          Enum.map(events, &Map.put(acc, &1.email, js))
      end
    end)
  end

  def build_emails(emails) do
    emails
    |> Enum.reduce([], fn {email, job_seeker}, acc ->
      [
        %Email{
          custom_id: UUID.uuid5(nil, email),
          job_seeker: job_seeker
        }
        | acc
      ]
    end)
  end

  def send_email(emails) do
    emails
    |> Enum.reduce([], fn email, acc ->
      case @sender.send(email) do
        %Email{state: :success} -> acc
        _ -> [email | acc]
      end
    end)
  end

  defp filter_by_empty_event_payload(events) do
    Enum.filter(events, fn event -> not is_nil(event.payload) end)
  end

  defp filter_by_date(events, last_month) do
    Enum.filter(events, fn event ->
      event.time
      |> Timex.parse!("{ISO:Extended:Z}")
      |> DateTime.to_date()
      |> Date.compare(last_month)
      |> (&(&1 == :eq)).()
    end)
  end

  defp filter_by_delegate_contact(events) do
    Enum.filter(events, fn event ->
      {payload, _} = Code.eval_string(event.payload)
      payload.contact_delegate == "on"
    end)
  end
end
