defmodule Vae.MailerWorker do
  use GenServer

  alias Vae.Mailer.{CsvExtractor, Sender}

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
    emails = CsvExtractor.extract(path)
    {:reply, emails, state ++ emails}
  end

  @impl true
  def handle_call(:save, _from, emails) do
    Enum.each(emails, fn email -> :ets.insert(:emails, {email.custom_id, email}) end)
    {:reply, emails, emails}
  end

  @impl true
  def handle_cast(:send, emails) do
    Enum.each(emails, fn email ->
      Sender.send(
        email,
        email.job_seeker.geolocation["administrative"] |> List.first()
      )
    end)

    {:noreply, emails}
  end
end
