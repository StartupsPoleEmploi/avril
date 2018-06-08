defmodule Vae.PlacesClient do
  @doc "Retrieve usage for places indices"
  @callback get(Map.t()) :: %{ok: [Map.t()], error: [Map.t()]}
end
