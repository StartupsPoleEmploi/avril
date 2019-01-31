defmodule Vae.Search.Client do
  @type geoloc :: Map.t()

  @doc "Retrieve delegates from certifiers and geoloc"
  @callback get_delegates([Vae.Certifier.t()], geoloc) :: {:ok, Map.t()} | {:error, String.t()}

  @doc "Retrieve index name from a model"
  @callback get_index_name(Struct) :: String.t()
end
