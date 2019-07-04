defmodule Vae.Delegates.Api do
  def get_france_vae_academies() do
    GenServer.call(:france_vae, :get_academies)
  end

  def get_france_vae_meetings(nil), do: []

  def get_france_vae_meetings(academy_id) do
    GenServer.call(:france_vae, {:get_meetings, academy_id})
  end
end
