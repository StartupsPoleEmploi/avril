defmodule Vae.Meetings do
  require Logger

  @state_holder Application.get_env(:vae, :meetings_state_holder)

  defdelegate get(delegate), to: @state_holder

  defdelegate all(), to: @state_holder

  defdelegate fetch(name), to: @state_holder

  defdelegate fetch_all(), to: @state_holder

  defdelegate register(meeting_id, application), to: @state_holder

  defdelegate get_by_meeting_id(meeting_id), to: @state_holder

  def get_france_vae_academies() do
    if Process.whereis(:france_vae) do
      GenServer.call(:france_vae, :get_academies)
    else
      Logger.warn("France VAE gen server not started")
      []
    end
  end
end
