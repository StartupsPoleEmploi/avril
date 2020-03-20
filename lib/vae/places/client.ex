defmodule Vae.Places.Client do
  @callback current_month_stats({String.t(), Map.t()}) :: %{ok: [Map.t()], error: [Map.t()]}

  @callback get_geoloc_from_postal_code(String.t()) :: Map.t()

  @callback get_geoloc_from_address(String.t()) :: Map.t()

  @callback get_geoloc_from_address(Map.t()) :: Map.t()
end
