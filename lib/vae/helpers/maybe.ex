defmodule Vae.Maybe do
  def map(nil, _cb), do: nil
  def map(value, cb), do: cb.(value)
end
