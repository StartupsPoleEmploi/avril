defmodule Vae.Maybe do
  def map(nil, _cb), do: nil
  def map(value, cb), do: cb.(value)

  def to_integer(v) when is_binary(v), do: String.to_integer(v)
  def to_integer(v), do: v

  def if(data, bool, do_action, else_action\\fn v -> v end)
  def if(data, bool, do_action, else_action)
    when is_function(bool, 1),
    do: if(data, bool.(data), do_action, else_action)

  def if(data, true, do_action, _else_action)
    when is_function(do_action, 1),
    do: do_action.(data)

  def if(data, false, _do_action, else_action)
    when is_function(else_action, 1),
    do: else_action.(data)

  def try(val, attrs, default_value \\ nil)
  def try(val, fnc, default_value) when is_function(fnc), do: try(fnc.(val), nil, default_value)
  def try(val, index, default_value) when is_list(val) and is_integer(index), do: try(val, &Enum.at(&1, index), default_value)
  def try(val, key, default_value) when is_map(val) and not is_nil(key) and (is_atom(key) or is_binary(key)), do: try(val, &Map.get(&1, key), default_value)
  def try(val, keys, default_value) when is_list(keys) do
    Enum.reduce(keys, val, &try(&2, &1, default_value))
  end
  def try(_val, params, default_value) when not is_nil(params), do: default_value
  def try(val, _, default_value), do: val || default_value
end
