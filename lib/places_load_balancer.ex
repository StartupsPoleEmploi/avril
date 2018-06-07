defmodule Vae.PlacesLoadBalancer do
  use Agent
  
  @name __MODULE__

  def start_link(), do: start_link([])
  def start_link(_opts), do: Agent.start_link(&poll/0, name: @name) 
  
  def get_indice(), do: Agent.get(@name, &(&1))
  
  def poll() do
#    receive do
#      after 
#        5_000 -> 
#          poll()
#    end
  end
end
