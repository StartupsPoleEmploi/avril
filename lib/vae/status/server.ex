defmodule Vae.Status.Server do
  require Logger
  use GenServer

  @name Status
  @ets_table :status
  @ets_key :message

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init(_delegate) do
    Logger.info("Init status server")
    PersistentEts.new(@ets_table, "priv/tabs/#{@ets_table}.tab", [
      :set,
      :named_table,
      :public
    ])
    {:ok, nil}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, get_status(), state}
  end

  @impl true
  def handle_cast({:set, status}, state) when is_binary(status) do
    set_status([status: status])
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set, data}, state) do
    set_status(data)
    {:noreply, state}
  end

  def handle_cast({:delete}, state) do
    delete_status()
    {:noreply, state}
  end

  defp get_status() do
    case :ets.lookup(@ets_table, @ets_key) do
      [{@ets_key, value}] -> value
      [] -> nil
    end
  end

  defp set_status(data) do
    defaults = %{level: :info, starts_at: nil, ends_at: nil}
    data = Enum.into(data, defaults)
    :ets.insert(@ets_table, {@ets_key, data})
  end

  defp delete_status() do
    :ets.insert(@ets_table, {@ets_key, nil})
  end
end
