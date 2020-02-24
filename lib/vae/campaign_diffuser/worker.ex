defmodule Vae.CampaignDiffuser.Worker do
  require Logger

  alias Vae.{JobSeeker, JobSeekerEmail, Mailer}

  @extractor Vae.CampaignDiffuser.FileExtractor.CsvExtractor

  @doc false
  def start_link() do
    Task.start_link(fn ->
      PersistentEts.new(:pending_emails, "priv/tabs/pending_emails.tab", [:named_table, :public])
      |> :ets.tab2list()
      |> Enum.map(fn {_custom_id, email} -> email end)
      |> run()
    end)
  end

  def run(pending_emails) do
    receive do
      {:execute, {type, from}} ->
        execute(pending_emails, type, from)

      {:flush} ->
        :ets.delete_all_objects(:pending_emails)

      {:get_pending_emails, sender} ->
        send(sender, :ets.tab2list(:pending_emails))

      msg ->
        Logger.error(fn -> inspect(msg) end)
    end
  end

  def execute(pending_emails, type, from) do
    Logger.info("Start extracting job seekers")

    @extractor.build_enumerable(type, from)
    |> case do
      {:ok, csv} ->
        csv
        |> Flow.from_enumerable(max_demand: 500, window: Flow.Window.count(100))
        |> @extractor.extract_lines_flow()
        |> @extractor.build_job_seeker_flow()
        |> @extractor.add_geolocation_flow()
        |> Flow.on_trigger(fn job_seekers ->
          Logger.info("Insert or update #{length(job_seekers)} job seekers")

          inserted_job_seekers = JobSeeker.insert_or_update!(job_seekers)

          Logger.info("#{length(inserted_job_seekers)} inserted")

          {inserted_job_seekers, []}
        end)
        |> Flow.shuffle(window: Flow.Window.count(30))
        |> Flow.reduce(fn -> [] end, fn job_seeker, acc ->
          email =
            build_email(job_seeker)
            |> persist()

          [email | acc]
        end)
        |> Flow.on_trigger(fn emails ->
          Logger.info("Try to send #{length(emails)} emails")

          with {:ok, emails_sent} <- send_emails(emails),
               _ <- remove(emails_sent) do
            Logger.info("#{length(emails_sent)}/#{length(emails)} sent")
          end

          {[], []}
        end)
        |> Flow.run()

      {:error, type} ->
        Logger.error("Error while extract #{type}")
        nil
    end

    Logger.info("End of extracting job seekers")
  end

  defp build_email(job_seeker) do
    JobSeekerEmail.campaign(job_seeker)
  end

  defp send_emails(emails) do
    Mailer.send(emails)
  end

  defp persist(email) do
    :ets.insert(:pending_emails, {email.provider_options.custom_id, email})
    email
  end

  defp remove(emails) do
    Enum.each(emails, fn email ->
      :ets.delete(:pending_emails, email.provider_options.custom_id)
    end)

    emails
  end
end
