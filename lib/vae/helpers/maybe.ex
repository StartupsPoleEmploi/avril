defmodule Vae.Maybe do
  def map(nil, _cb), do: nil
  def map(value, cb), do: cb.(value)

  def to_integer(v) when is_binary(v), do: String.to_integer(v)
  def to_integer(v), do: v

  def if(data, bool, do_action, else_action\\fn v -> v end)
  def if(data, true, do_action, _else_action)
    when is_function(do_action, 1),
    do: do_action.(data)

  def if(data, false, _do_action, else_action)
    when is_function(else_action, 1),
    do: else_action.(data)

end
