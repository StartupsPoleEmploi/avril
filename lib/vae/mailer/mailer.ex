defmodule Vae.Mailer do
  def extract(path) do
    GenServer.call(MailerWorker, {:extract, path}, :infinity)
  end

  def send(emails) do
    GenServer.call(MailerWorker, {:send, emails}, :infinity)
  end

  @doc """
  Utility function to flush both state and ETS
  """
  def flush() do
    GenServer.call(MailerWorker, :flush)
  end
end
