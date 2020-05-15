defmodule Vae.Maybe do
  def map(nil, _cb), do: nil
  def map(value, cb), do: cb.(value)

  def to_integer(v) when is_binary(v), do: String.to_integer(v)
  def to_integer(v), do: v
end
