defmodule Vae.List do
  def uniq_concat(list1, list2, keyify_fn) do
    Enum.reduce(list1 ++ (list2 || []), %{}, fn
      elem, result -> Map.put(result, keyify_fn.(elem), elem)
    end)
    |> Map.values
  end
end