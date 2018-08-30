defmodule Vae.Mailer.Worker do
  use GenServer

  alias Vae.Mailer.{Email, Sender}
  alias Vae.{Event, JobSeeker}
  alias Vae.Repo.NewRelic, as: Repo
  alias Ecto.Changeset

  @extractor Application.get_env(:vae, :extractor)

  @name MailerWorker

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(_state) do
    PersistentEts.new(:emails, "emails.tab", [:named_table])
    new_state = :ets.tab2list(:emails) |> Enum.map(fn {_custom_id, email} -> email end)
    {:ok, new_state}
  end

  @impl true
  def handle_call({:extract, path}, _from, state) do
    with job_seekers <- @extractor.extract(path),
         inserted_job_seekers <- insert_or_update!(job_seekers),
         emails <- build_emails(inserted_job_seekers),
         :ok <- persist(emails) do
      new_state = emails ++ state
      {:reply, new_state, new_state}
    end
  end

  @impl true
  def handle_call(:send, _from, emails) do
    new_emails = Enum.flat_map(emails, &Sender.send/1)
    {:reply, nil, new_emails}
  end

  @impl true
  def handle_cast(:persist, emails) do
    persist(emails)
    {:noreply, emails}
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
    Enum.each(emails, fn email -> :ets.insert(:emails, {email.custom_id, email}) end)
    # Temporary
    :ok
  end

  defp insert_or_update!(job_seekers) do
    Enum.map(job_seekers, fn job_seeker ->
      case Repo.get_by(JobSeeker, email: job_seeker.email) do
        nil ->
          %JobSeeker{}
          |> Vae.JobSeeker.changeset(job_seeker)
          |> Repo.insert!()

        existing_job_seeker ->
          existing_job_seeker
          |> Changeset.change(job_seeker)
          |> Repo.update!()
      end
    end)
  end
end
