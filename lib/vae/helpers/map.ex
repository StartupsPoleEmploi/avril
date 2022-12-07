defmodule Vae.Map do
  def ensure_atom_keys(map) do
    Enum.reduce(map, %{}, fn ({key, val}, acc) ->
      Map.put(acc,
        case key do
          k when is_binary(k) -> String.to_atom(k)
          other -> other
        end,
        case val do
          %{__struct__: _} = v -> v
          v when is_map(v) -> Vae.Map.ensure_atom_keys(v)
          other -> other
        end
      )
    end)
  end

  def map_values(map, map_func) do
    Map.new(map, fn {k, v} -> {k, map_func.({k, v})} end)
  end

  def transform_if_present(map, key, transform_fn) do
    case map[key] do
      nil -> map
      value -> Map.put(map, key, transform_fn.(value))
    end
  end

  def transform_if_present(map, list) when is_list(list) do
    Enum.reduce(list, map, fn({key, transform_fn}, acc) -> transform_if_present(acc, key, transform_fn) end)
  end

  def params_with_ids(params) do
    map_values(params, fn {_k, v} -> Vae.String.to_id(v) end)
  end

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end
end
