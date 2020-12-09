defmodule Vae.Enum do
  def join_keep_nil(enumerable, joiner \\ "", accumulator \\ nil) do
    Enum.reduce(enumerable, accumulator, fn
      nil, acc -> acc
      el, nil -> el
      el, acc -> "#{acc}#{joiner}#{el}"
    end)
  end

  def reject_and_find(list, func) do
    Enum.reduce(list, {[], nil}, fn el, {result, found} ->
      case func.(el) do
        true -> {result, found || el}
        false -> {[el | result], found}
      end
    end)
  end
end
