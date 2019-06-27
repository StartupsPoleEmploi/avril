defmodule Vae.Mailer do
  def execute() do
    {:ok, pid} = Vae.Mailer.Worker.start_link()

    send(
      pid,
      {:execute,
       "priv/campaigns/emails_#{Date.utc_today() |> to_string() |> String.replace("-", "_")}.csv"}
    )
  end

  def execute(path) do
    {:ok, pid} = Vae.Mailer.Worker.start_link()

    send(
      pid,
      {:execute, path}
    )
  end

  def get_pending_emails() do
    {:ok, pid} = Vae.Mailer.Worker.start_link()
    send(pid, {:get_pending_emails, self()})
  end

  @doc """
  Utility function to flush both state and ETS
  """
  def flush() do
    {:ok, pid} = Vae.Mailer.Worker.start_link()
    send(pid, :flush)
  end
end
