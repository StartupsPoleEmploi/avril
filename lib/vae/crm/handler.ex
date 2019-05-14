defmodule Vae.CRM.Handler do
  require Logger
  use GenServer

  alias Vae.CRM.Transactional.Monthly

  def child_spec(type) do
    %{
      id: __MODULE__,
      restart: :temporary,
      start: {__MODULE__, :start_link, [[type: type]]},
      type: :worker
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, args[:type]}
  end

  def handle_call({:execute, from_date}, _from, :monthly = state) do
    Monthly.execute(from_date)
    {:reply, [], state}
  end

  def handle_call({:execute, _args}, _from, state) do
    Logger.error(fn -> inspect("Unable to execute #{state}, the type #{state} is unknown") end)
    {:reply, [], state}
  end
end
