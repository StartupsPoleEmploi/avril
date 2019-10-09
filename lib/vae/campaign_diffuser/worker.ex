defmodule Vae.CampaignDiffuser.Worker do
  require Logger

  alias Vae.{JobSeeker, JobSeekerEmail, Mailer}

  @extractor Vae.Mailer.FileExtractor.CsvExtractor

  @doc false
  def start_link() do
    Task.start_link(fn ->
      PersistentEts.new(:pending_emails, "pending_emails.tab", [:named_table, :public])
      |> :ets.tab2list()
      |> Enum.map(fn {_job_seeker_id, email} -> email end)
      |> run()
    end)
  end

  def run(pending_emails) do
    receive do
      {:execute, path} ->
        execute(pending_emails, path)

      {:flush} ->
        :ets.delete_all_objects(:pending_emails)

      {:get_pending_emails} ->
        send_emails(:ets.tab2list(:pending_emails))

      msg ->
        Logger.error(fn -> inspect(msg) end)
    end
  end

  def execute(pending_emails, path) do
    Logger.info("Start extracting job seekers")

    @extractor.build_enumerable(path)
    |> Flow.from_enumerable(max_demand: 100, window: Flow.Window.count(1_000))
    |> @extractor.extract_lines_flow()
    |> @extractor.build_job_seeker_flow()
    |> @extractor.add_geolocation_flow()
    |> Flow.on_trigger(fn job_seekers ->
      Logger.info("Insert or update #{length(job_seekers)} job seekers")

      inserted_job_seekers = insert_or_update!(job_seekers)

      Logger.info("#{length(inserted_job_seekers)} inserted")

      {inserted_job_seekers, []}
    end)
    |> Flow.shuffle(window: Flow.Window.count(50))
    |> Flow.reduce(fn -> pending_emails end, fn job_seeker, acc ->
      email =
        build_email(job_seeker)
        |> persist()

      [email | acc]
    end)
    |> Flow.on_trigger(fn emails ->
      Logger.info("Try to send #{length(emails)} emails")

      emails_sent =
        send_emails(emails)
        |> remove()

      Logger.info("#{length(emails_sent)}/#{length(emails)} sent")

      {[], []}
    end)
    |> Flow.run()

    Logger.info("End of extracting job seekers")
  end

  defp build_email(job_seeker) do
    JobSeekerEmail.campaign(job_seeker)
  end

  defp send_emails(emails) do
    {:ok, sent_emails} = Mailer.send(emails)
    sent_emails
  end

  defp persist(email) do
    :ets.insert(:pending_emails, {email.assigns.job_seeker_id, email})
    email
  end

  defp remove(emails) do
    Enum.each(emails, fn email -> :ets.delete(:pending_emails, email.assigns.job_seeker_id) end)
    emails
  end
end
