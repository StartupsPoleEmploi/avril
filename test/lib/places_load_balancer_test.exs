defmodule Vae.PlacesLoadBalancerTest do
  use ExUnit.Case, async: true

  describe "theory" do
    test "test and learn" do
      map = %{
        "foo" => "123",
        "bar" => "456"
      }

      {index, _usage} =
        map
        |> Stream.with_index()
        |> Flow.from_enumerable()
        |> Flow.partition()
        |> Flow.map(&Vae.PlacesClient.InMemory.get/1)
        |> Enum.to_list()
        |> Enum.min_by(fn {_i, v} -> v end)

      assert Enum.at(map, index) == {"foo", "123"}
    end
  end

  describe "on use" do
    test "init and update index" do
      Vae.PlacesLoadBalancer.start_link()

      assert Vae.PlacesLoadBalancer.get_index() == {"foo", "foo_search"}

      :ok = Agent.update(Vae.PlacesLoadBalancer, fn _state -> %{} end)
      assert Vae.PlacesLoadBalancer.get_index() == %{}

      Vae.PlacesLoadBalancer.update_index()
      assert Vae.PlacesLoadBalancer.get_index() == {"foo", "foo_search"}
    end
  end
end
