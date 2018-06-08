defmodule Vae.PlacesLoadBalancerTest do
  use ExUnit.Case

  describe "theory" do
    test "test and learn" do
      map = %{
        "foo" => "123",
        "bar" => "456"
      }
      
      {index, _usage} = map
      |> Stream.with_index()
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(&Vae.PlacesClient.InMemory.get/1)
      |> Enum.to_list
      |> Enum.min_by(fn {_i, v} -> v end)

      assert Enum.at(map, index) == {"foo", "123"}
    end
  end
  
  describe "on use" do
    setup do
      Vae.PlacesLoadBalancer.start_link(%{})
      :ok
    end

    test "test init ok" do
      :ok = Vae.PlacesLoadBalancer.poll()
      assert Vae.PlacesLoadBalancer.get_indice() == {"foo", "123456"}
    end
    
  end
  
end
