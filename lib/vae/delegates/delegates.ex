defmodule Vae.Delegates do
  def get_france_vae_academies() do
    GenServer.call(:france_vae, :get_academies)
  end

  def get_france_vae_meetings(nil), do: []

  def get_france_vae_meetings(academy_id) do
    GenServer.call(:france_vae, {:get_meetings, academy_id})
  end

  def post_meeting_registration(academy_id, meeting_id, user) do
    GenServer.call(:france_vae, {:post_meeting_registration, academy_id, meeting_id, user})
  end

  def get_afpa_meetings() do
    GenServer.call(Afpa, :get_meetings)
  end

  def refresh_afpa_meetings() do
    GenServer.cast(Afpa, :refresh)
  end

end
