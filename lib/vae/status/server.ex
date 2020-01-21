defmodule Vae.Status.Server do
  require Logger
  use GenServer

  @tab_name 'priv/tabs/status.tab'
  @tab_key :message

  ##############
  ### Server ###
  ##############

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: Status)
  end

  @impl true
  def init(_state) do
    Logger.info("Init status server")
    :dets.open_file(@tab_name, [type: :set])
  end

  @impl true
  def handle_call(:get, _from, _state) do
    {:reply, get_status(), nil}
  end

  @impl true
  def handle_cast({:set, status}, _state) when is_binary(status) do
    set_status([status: status])
    {:noreply, nil}
  end

  @impl true
  def handle_cast({:set, data}, _state) do
    set_status(data)
    {:noreply, nil}
  end

  def handle_cast({:delete}, _state) do
    delete_status()
    {:noreply, nil}
  end

  #############
  #### API ####
  #############

  defp get_status() do
    case :dets.lookup(@tab_name, @tab_key) do
      [{@tab_key, value}] -> value
      [] -> nil
    end
  end

  defp set_status(data) do
    defaults = %{level: :info, starts_at: nil, ends_at: nil}
    data = Enum.into(data, defaults)
    :dets.insert(@tab_name, {@tab_key, data})
  end

  defp delete_status() do
    :dets.delete(@tab_name, @tab_key)
  end
end
