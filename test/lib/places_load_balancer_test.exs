defmodule Vae.PlacesLoadBalancerTest do
  use ExUnit.Case
  
  defmodule Vae.PlacesClientMock do
    
    def get_value(key) do
      case key do
        :foo -> :rand.uniform(10)  
        :bar -> :rand.uniform(20) + 11 
      end
      
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
      |> Enum.reduce(%{k => 0}, fn %{"t" => _t, "v" => v}, acc ->
        Map.update!(acc, k, &(&1 + v))
      end)
    end
  end
  
  test "test get" do
    map = %{
      foo: "123",
      bar: "456"
    }
    
    assert map
    |> Flow.from_enumerable
    |> Flow.partition()
    |> Flow.map(&Vae.PlacesClientMock.get/1)
    |> Enum.to_list
    |> Enum.min_by(fn map -> 
      map
      |> Map.values
      |> hd()
    end)
    |> Map.keys
    |> hd() == :foo
  end
  
end
