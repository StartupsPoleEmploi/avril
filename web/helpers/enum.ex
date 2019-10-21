defmodule Vae.Enum do
  def join_keep_nil(enumerable, joiner\\"", accumulator\\nil) do
    Enum.reduce(enumerable, accumulator, fn
      nil, acc -> acc
      el, nil -> el
      el, acc -> "#{acc}#{joiner}#{el}"
    end)
  end
end