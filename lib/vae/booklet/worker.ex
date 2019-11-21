defmodule Vae.Booklet.Worker do
  use GenServer

  alias Vae.Booklet.Cerfa

  def start_link(server_id) do
    IO.puts("Starting booklet server #{server_id}")

    GenServer.start_link(
      __MODULE__,
      [],
      name: via_tuple(server_id)
    )
  end

  @impl true
  def init(_) do
    {:ok, Cerfa.new_cerfa()}
  end

  @impl true
  def handle_call({:set, data}, _from, cerfa) do
    IO.inspect(data)
    {:reply, cerfa, cerfa}
  end

  def set({data, server_id}) do
    GenServer.call(via_tuple(server_id), {:set, data})
  end

  def via_tuple(server_id) do
    Vae.Booklet.ProcessRegistry.via_tuple({__MODULE__, server_id})
  end
end
