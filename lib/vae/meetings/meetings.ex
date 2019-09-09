defmodule Vae.Meetings do
  alias Vae.Meetings.StateHolder

  def get(nil), do: []

  defdelegate get(delegate), to: StateHolder

  defdelegate all(), to: StateHolder

  def get_by_meeting_id(nil), do: %Vae.Meetings.Meeting{}

  defdelegate get_by_meeting_id(meeting_id), to: StateHolder

  def get_france_vae_academies() do
    GenServer.call(:france_vae, :get_academies)
  end

  def register_to_france_vae_meeting(academy_id, meeting_id, application) do
    GenServer.call(:france_vae, {:register_to_meeting, academy_id, meeting_id, application})
  end

  def refresh_afpa_meetings() do
    nil
  end
end
