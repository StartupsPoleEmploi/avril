defmodule Vae.Meetings do
  require Logger
  alias Vae.{Meeting, UserApplication}

  @meeting_sources [
    # :afpa,
    :france_vae
  ]

  def get_france_vae_academies() do
    safe_genserver_call(:france_vae, :get_academies) || []
  end

  def fetch_meetings() do
    Enum.each(@meeting_sources, &fetch_meetings(&1))
  end

  def fetch_meetings(source) when source in @meeting_sources do
    meetings = safe_genserver_call(source, :fetch, 1000 * 60 * 15)
    Logger.info("#{length(meetings)} inserted or updated in source #{source}")
  end

  def register(%Meeting{source: source} = meeting, %UserApplication{} = application) do
    safe_genserver_call(source, {:register, meeting, application}, 15_000)
  end

  defp safe_genserver_call(source, params, timeout \\ 5_000)

  defp safe_genserver_call(source, params, timeout) when is_binary(source), do:
    safe_genserver_call(String.to_atom(source), params, timeout)

  defp safe_genserver_call(source, params, timeout) do
    if Process.whereis(source) do
      GenServer.call(source, params, timeout)
    else
      :ok = Logger.warn("#{source} gen server not started")
      nil
    end
  end
end
