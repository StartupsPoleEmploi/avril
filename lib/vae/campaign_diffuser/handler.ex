defmodule Vae.CampaignDiffuser.Handler do
  def execute_registered(date), do: execute(:reinscrits, date)

  def execute_new_registered(date), do: execute(:primo_inscrits, date)

  def execute(type, date) do
    {:ok, pid} = Vae.CampaignDiffuser.Worker.start_link()

    send(
      pid,
      {:execute, {type, date}}
    )
  end

  def get_pending_emails() do
    {:ok, pid} = Vae.CampaignDiffuser.Worker.start_link()
    send(pid, {:get_pending_emails})
  end

  @doc """
  Utility function to flush both state and ETS
  """
  def flush() do
    {:ok, pid} = Vae.CampaignDiffuser.Worker.start_link()
    send(pid, {:flush})
  end
end
