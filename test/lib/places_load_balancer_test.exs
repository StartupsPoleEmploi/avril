defmodule Vae.PlacesLoadBalancerTest do
  use ExUnit.Case, async: true
  
  defmodule Vae.PlacesClientMock do
    
    def get({k, v}) do
      IO.inspect k, label: "IN"
      result = %{
        total_read_operations: [
          %{
            "t" => 1528243200000,
            "v" => :rand.uniform(1_000) 
          },
          %{
            "t" => 1528243200001,
            "v" => :rand.uniform(1_000) 
          }
        ]
      } 
      |> Map.get(:total_read_operations)
      |> Enum.reduce(%{k => 0}, fn %{"t" => _t, "v" => v}, acc ->
        Map.update!(acc, k, &(&1 + v))
      end)
     
      case k do
        :foo -> :timer.sleep(5_000)
        _ -> :timer.sleep(3_000)
      end
     
      IO.inspect "OUT"
      result
      
    end
  end
  
  test "test get" do
    map = %{
      foo: "123",
      bar: "456"
    }
    result = 
      map
      |> Flow.from_enumerable
      |> Flow.partition()
      |> Flow.map(&Vae.PlacesClientMock.get/1)
      |> Flow.reduce(fn -> %{} end, fn api_result, acc ->
        key = Map.keys(api_result)
        |> hd()
        api_value = Map.get(api_result, key)
        Map.get(acc, key)
        |> case do
             nil -> api_result
             value when api_value < value -> api_result   
             _ -> acc
           end
      end)
      |> Enum.to_list
      |> Enum.min_by(fn map -> 
        map
        |> elem(1)
      end)
  end
  
end
