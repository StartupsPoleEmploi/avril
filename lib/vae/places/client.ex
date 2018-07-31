defmodule Vae.Places.Client do
  @doc "Retrieve statistics of total read operations for the current month"
  @callback current_month_stats({String.t(), Map.t()}) :: %{ok: [Map.t()], error: [Map.t()]}

  @doc "Retrieve geolocation from postal code"
  @callback get_geoloc_from_postal_code(String.t()) :: Map.t()

  @doc "Retrieve geolocation from address"
  @callback get_geoloc_from_address(String.t()) :: Map.t()
end
