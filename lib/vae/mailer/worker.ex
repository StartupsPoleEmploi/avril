defmodule Vae.Mailer.Worker do
  alias Ecto.Changeset
  alias Vae.JobSeeker
  alias Vae.Mailer.Email
  alias Vae.Repo

  require Logger

  @extractor Application.get_env(:vae, :extractor)

  @sender Application.get_env(:vae, :sender)

  @doc false
  def start_link() do
    Task.start_link(fn ->
      PersistentEts.new(:pending_emails, "pending_emails.tab", [:named_table, :public])
      |> :ets.tab2list()
      |> Enum.map(fn {_custom_id, email} -> email end)
      |> run()
    end)
  end

  def run(pending_emails) do
    receive do
      {:execute, path} ->
        execute(pending_emails, path)

      {:flush} ->
        :ets.delete_all_objects(:pending_emails)

      {:get_pending_emails, sender} ->
        send(sender, :ets.tab2list(:pending_emails))

      msg ->
        Logger.error(fn -> inspect(msg) end)
    end
  end

  def execute(pending_emails, path) do
    Logger.info("Start extracting job seekers")

    @extractor.build_enumerable(path)
    |> Flow.from_enumerable(max_demand: 100, min_demand: 50, window: Flow.Window.count(1_000))
    |> @extractor.extract_lines_flow()
    |> @extractor.build_job_seeker_flow()
    |> @extractor.add_geolocation_flow()
    |> Flow.on_trigger(fn job_seekers ->
      Logger.info("Insert or update #{length(job_seekers)} job seekers")

      inserted_job_seekers = insert_or_update!(job_seekers)

      Logger.info("#{length(inserted_job_seekers)} inserted")

      {inserted_job_seekers, []}
    end)
    |> Flow.shuffle(window: Flow.Window.count(100))
    |> Flow.reduce(fn -> pending_emails end, fn job_seeker, acc ->
      email =
        build_email(job_seeker)
        |> persist()

      [email | acc]
    end)
    |> Flow.on_trigger(fn emails ->
      Logger.info("Try to send #{length(emails)} emails")

      emails_sent =
        send_email(emails)
        |> remove()

      Logger.info("#{length(emails_sent)}/#{length(emails)} sent")

      {[], []}
    end)
    |> Flow.run()

    Logger.info("End of extracting job seekers")
  end

  defp build_email(job_seeker) do
    %Email{
      custom_id: UUID.uuid5(nil, job_seeker.email),
      job_seeker: job_seeker
    }
  end

  defp send_email(emails) do
    emails
    |> Enum.reduce([], fn email, acc ->
      case @sender.send(email) do
        %Email{state: :success} -> [email | acc]
        _ -> acc
      end
    end)
  end

  defp persist(email) do
    :ets.insert(:pending_emails, {email.custom_id, email})
    email
  end

  defp remove(emails) do
    Enum.each(emails, fn email -> :ets.delete(:pending_emails, email.custom_id) end)
    emails
  end

  defp insert_or_update!(job_seekers) do
    Enum.map(job_seekers, fn job_seeker ->
      case Repo.get_by(JobSeeker, email: job_seeker.email) do
        nil ->
          insert!(job_seeker)

        actual_job_seeker ->
          update!(actual_job_seeker, job_seeker)
      end
    end)
  end

  defp insert!(job_seeker) do
    %JobSeeker{}
    |> JobSeeker.changeset(job_seeker)
    |> Repo.insert!()
  end

  defp update!(current_job_seeker, job_seeker) do
    current_job_seeker
    |> Changeset.change(job_seeker)
    |> Repo.update!()
  end
end
