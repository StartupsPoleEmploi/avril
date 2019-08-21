defmodule Vae.Delegates do
  def get_france_vae_academies() do
    GenServer.call(:france_vae, :get_academies)
  end

  def get_france_vae_meetings(nil), do: []

  def get_france_vae_meetings(academy_id) do
    GenServer.call(:france_vae, {:get_meetings, academy_id})
  end

  def register_to_france_vae_meeting(academy_id, meeting_id, application) do
    GenServer.call(:france_vae, {:register_to_meeting, academy_id, meeting_id, application})
  end
end
