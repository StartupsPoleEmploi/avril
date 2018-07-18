defmodule Vae.MailerWorker do
  use GenServer

  @name MailerWorker

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(state) do
    PersistentEts.new(:emails, "emails.tab", [:named_table])
    {:ok, state}
  end

  @impl true
  def handle_call({:extract, path}, _from, state) do
    emails = Vae.Crm.extract(path)
    {:reply, emails, state ++ emails}
  end

  @impl true
  def handle_call(:save_email, _from, emails) do
    Enum.each(emails, fn email -> :ets.insert(:emails, {email.custom_id, email}) end)
    {:reply, emails, emails}
  end

  @impl true
  def handle_cast(:send, emails) do
    Enum.each(emails, fn email ->
      Vae.Mailer.send_campaign_email(
        email.job_seeker,
        email.job_seeker.geolocation["administrative"] |> List.first()
      )
    end)

    {:noreply, emails}
  end
end
