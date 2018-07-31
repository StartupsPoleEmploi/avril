defmodule Vae.Mailer do
  def extract(path) do
    GenServer.call(MailerWorker, {:extract, path}, :infinity)
  end

  def send() do
    GenServer.call(MailerWorker, :send)
  end

  def persist() do
    GenServer.cast(MailerWorker, :persist)
  end

  def handle_events(events) do
    GenServer.cast(MailerWorker, {:handle_events, events})
  end
end
