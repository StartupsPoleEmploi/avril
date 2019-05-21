defmodule Vae.Map do
  def map_values(map, map_func) do
    Map.new(map, fn {k, v} -> {k, map_func.(v)} end)
  end

  def params_with_ids(params) do
    map_values(params, fn v -> Vae.String.to_id(v) end)
  end
end