defmodule Vae.Delegates.Api do
  def get_france_vae_academies() do
    GenServer.call(:france_vae, :get_academies)
  end
end
