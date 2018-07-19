defmodule Vae.Mailer.Worker do
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
    new_state = state ++ emails
    {:reply, nil, new_state}
  end

  @impl true
  def handle_call(:send, _from, emails) do
    new_emails = Enum.flat_map(emails, &Sender.send/1)
    {:reply, nil, new_emails}
  end

  @impl true
  def handle_cast(:persist, emails) do
    Enum.each(emails, fn email -> :ets.insert(:emails, {email.custom_id, email}) end)
    {:noreply, emails}
  end
end
