defmodule Vae.Search.Client do
  @type geoloc :: Map.t()

  @doc "Retrieve delegates from certifiers and geoloc"
  @callback get_delegates([Vae.Certifier.t()], geoloc) :: {:ok, Map.t()} | {:error, String.t()}
end
