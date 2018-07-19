defmodule Vae.Mailer do
  def extract(path) do
    GenServer.call(MailerWorker, {:extract, path})
  end

  def save() do
    GenServer.call(MailerWorker, :save)
  end

  def send() do
    GenServer.cast(MailerWorker, :send)
  end
end
