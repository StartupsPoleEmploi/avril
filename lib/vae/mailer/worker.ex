defmodule Vae.Mailer.Worker do
  use GenServer

  alias Ecto.Changeset
  alias Vae.JobSeeker
  alias Vae.Mailer.Email
  alias Vae.Repo.NewRelic, as: Repo

  require Logger

  @extractor Application.get_env(:vae, :extractor)

  @sender Application.get_env(:vae, :sender)

  @name MailerWorker

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(_state) do
    PersistentEts.new(:pending_emails, "pending_emails.tab", [:named_table])
    new_state = :ets.tab2list(:pending_emails) |> Enum.map(fn {_custom_id, email} -> email end)
    {:ok, new_state}
  end

  @impl true
  def handle_call({:extract, path}, _from, state) do
    Logger.info("Start extracting job seekers")

    with job_seekers <- @extractor.extract(path),
         inserted_job_seekers <- insert_or_update!(job_seekers),
         emails <- build_emails(inserted_job_seekers),
         :ok <- persist(emails) do
      new_state =
        emails
        |> Kernel.++(state)
        |> Enum.uniq_by(& &1.custom_id)

      Logger.info("End of extracting job seekers")

      {:reply, new_state, new_state}
    end
  end

  @impl true
  def handle_call({:send, emails}, _from, _state) do
    Logger.info("Start sending #{length(emails)}")

    {emails_sent, remaining_emails} =
      emails
      |> Enum.flat_map(&@sender.send/1)
      |> Enum.split_with(fn email ->
        email.state == :success
      end)

    remove(emails_sent)

    Logger.info(
      "#{length(emails_sent)} emails sent, #{length(remaining_emails)} remaining emails"
    )

    {:reply, remaining_emails, remaining_emails}
  end

  @impl true
  def handle_call(:flush, _from, _state) do
    :ets.delete_all_objects(:pending_emails)
    {:reply, [], []}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end

  defp build_emails(job_seekers) do
    Enum.map(job_seekers, fn job_seeker ->
      %Email{
        custom_id: UUID.uuid5(nil, job_seeker.email),
        job_seeker: job_seeker
      }
    end)
  end

  defp persist(emails) do
    Enum.each(emails, fn email -> :ets.insert(:pending_emails, {email.custom_id, email}) end)
    # Temporary
    :ok
  end

  defp remove(emails) do
    Enum.each(emails, fn email -> :ets.delete(:pending_emails, email.custom_id) end)
    # Temporary
    :ok
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

  defp update!(actual_job_seeker, job_seeker) do
    actual_job_seeker
    |> Changeset.change(job_seeker)
    |> Repo.update!()
  end
end
