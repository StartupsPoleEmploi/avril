defmodule Vae.Meetings do
  require Logger

  def fetch_france_vae_meetings(academy_id) do
    Vae.Meetings.Server.fetch(:fvae, academy_id)
  end

  def index_france_vae_meetings(meetings) do
    Vae.Meetings.Server.index(meetings)
  end

  def get_france_vae_meetings(delegate) do
    Vae.Meetings.Server.get_by_delegate(delegate)
  end

  def register_france_vae_meetings(meeting_id, application) do
    Vae.Meetings.Server.register(meeting_id, application)
  end

  def get_france_vae_academies() do
    if Process.whereis(:france_vae) do
      GenServer.call(:france_vae, :get_academies)
    else
      Logger.warn("France VAE gen server not started")
      []
    end
  end
end
