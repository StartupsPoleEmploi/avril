defmodule Vae.Mailer.Api do

  def extract(path) do
    GenServer.call(MailerWorker, {:extract, path})
  end

  def save_email() do
    GenServer.call(MailerWorker, :save_email)
  end

  def send() do
    GenServer.cast(MailerWorker, :send)
  end

end
