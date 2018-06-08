defmodule Vae.PlacesLoadBalancer do
  use Agent

  @name __MODULE__

  @places_client Application.get_env(:vae, :places_client)

  @apis Application.get_env(:vae, :algolia_places_apis)

  def start_link(), do: start_link(%{})
  def start_link(state), do: Agent.start_link(fn -> state end, name: @name)

  def get_indice(), do: Agent.get(@name, &(&1))

  def poll() do
    Agent.update(
      @name,
      fn _state ->
        {index, _usage} =
          @apis
          |> Stream.with_index()
          |> Flow.from_enumerable()
          |> Flow.partition()
          |> Flow.map(&@places_client.get/1)
          |> Enum.to_list()
          |> Enum.min_by(fn {_index, value} -> value end)

          Enum.at(@apis, index)
        end
    )
   end
end
