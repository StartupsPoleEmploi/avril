defmodule Vae.Meetings do
  alias Vae.Meetings.StateHolder

  def get(nil), do: []

  defdelegate get(delegate), to: StateHolder

  defdelegate all(), to: StateHolder

  defdelegate fetch(name), to: StateHolder

  defdelegate fetch_all(), to: StateHolder

  defdelegate register(meeting, application), to: StateHolder

  def get_by_meeting_id(nil), do: %Vae.Meetings.Meeting{}

  defdelegate get_by_meeting_id(meeting_id), to: StateHolder

  def get_france_vae_academies() do
    GenServer.call(:france_vae, :get_academies)
  end
end
