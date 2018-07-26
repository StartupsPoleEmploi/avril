defmodule Vae.Places.LoadBalancerTest do
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
        |> Flow.map(&Vae.Places.Client.InMemory.current_month_stats/1)
        |> Enum.to_list()
        |> Enum.min_by(fn {_i, v} -> v end)

      assert Enum.at(map, index) == {"foo", "123"}
    end
  end

  describe "on use" do
    test "init and update index" do
      Vae.Places.LoadBalancer.start_link()

      assert Vae.Places.LoadBalancer.get_index_credentials() == {"foo", "foo_search"}

      :ok = Agent.update(Vae.Places.LoadBalancer, fn _state -> %{} end)
      assert Vae.Places.LoadBalancer.get_index_credentials() == %{}

      Vae.Places.LoadBalancer.update_index()
      assert Vae.Places.LoadBalancer.get_index_credentials() == {"foo", "foo_search"}
    end
  end
end
