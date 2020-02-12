defmodule Vae.CampaignDiffuser.Handler do
  def execute_registered(), do: execute(:reinscrits)

  def execute_new_registered(), do: execute(:primo_inscrits)

  def execute(type, from \\ 2) do
    {:ok, pid} = Vae.CampaignDiffuser.Worker.start_link()

    send(
      pid,
      {:execute, {type, from}}
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
    send(pid, :flush)
  end
end
