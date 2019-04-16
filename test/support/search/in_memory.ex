defmodule Vae.Search.Client.InMemory do
  @behaviour Vae.Search.Client

  def get_delegates(_certifiers, _geoloc) do
    {:error, "Return an error for testing"}
  end
end
