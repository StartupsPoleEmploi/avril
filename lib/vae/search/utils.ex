defmodule Vae.Search.Utils do
  @indice_prefix Application.get_env(:algolia, :indice_prefix)

  def get_index_name(model) do
    if is_atom(model) && Code.ensure_compiled?(model) do
      model
      |> to_string()
      |> String.split(".")
      |> List.last()
      |> String.downcase()
    else
      "#{model}"
    end
    |> String.replace_prefix("", "#{@indice_prefix}")
  end

  def string_keys_to_atom(hits) do
    Enum.map(hits, fn item ->
      Enum.reduce(item, %{}, fn {key, val}, acc ->
        Map.put(acc, String.to_atom(key), val)
      end)
    end)
  end
end