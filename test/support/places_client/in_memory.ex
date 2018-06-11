defmodule Vae.PlacesClient.InMemory do

  @behaviour Vae.PlacesClient

  def get_value(key) do
    case key do
      "foo" -> Enum.random(1..10)
      "bar" -> Enum.random(21..30)
      _    -> Enum.random(61..70)
    end
  end

  def get({{k, v} = map, index}) do
    {index, get(map)}
  end

  def get({k, _v}) do
    %{
      total_read_operations: [
        %{
          "t" => 1528243200000,
          "v" => get_value(k)
        },
        %{
          "t" => 1528243200001,
          "v" => get_value(k)
        }
      ]
    }
    |> Map.get(:total_read_operations)
    |> Enum.reduce(0, fn %{"t" => _t, "v" => v}, acc ->
      acc + v
    end)
  end
end
