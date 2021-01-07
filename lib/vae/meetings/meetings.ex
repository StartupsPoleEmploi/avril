defmodule Vae.Meetings do
  require Logger
  alias Vae.{Meeting, UserApplication}

  @meeting_sources [
    # :afpa,
    :france_vae
  ]

  def get_france_vae_academies() do
    if Process.whereis(:france_vae) do
      GenServer.call(:france_vae, :get_academies)
    else
      Logger.warn("France VAE gen server not started")
      []
    end
  end

  def fetch_meetings() do
    Enum.each(@meeting_sources, &fetch_meetings(&1))
  end

  def fetch_meetings(source) when source in @meeting_sources do
    if Process.whereis(source) do
      GenServer.call(source, :fetch, 1000 * 60 * 15)
    else
      Logger.warn("#{source} gen server not started")
    end
  end

  def register(%Meeting{source: source} = meeting, %UserApplication{} = application) do
    GenServer.call(source, {:register, meeting, application}, 15_000)
  end
end
