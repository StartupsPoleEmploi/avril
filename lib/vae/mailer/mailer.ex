defmodule Vae.Mailer do
  def extract(path) do
    GenServer.call(MailerWorker, {:extract, path})
  end

  def persist() do
    GenServer.cast(MailerWorker, :persist)
  end

  def send() do
    GenServer.call(MailerWorker, :send)
  end
end
