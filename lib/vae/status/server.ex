defmodule Vae.Status.Server do
  require Logger
  use GenServer

  @tab_name 'priv/tabs/status.tab'
  @tab_key :messages

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

  def handle_cast({:delete, id}, _state) do
    delete_status(id)
    {:noreply, nil}
  end

  #############
  #### API ####
  #############

  defp get_status() do
    case :dets.lookup(@tab_name, @tab_key) do
      [{@tab_key, value}] -> value || []
      [] -> []
    end
  end

  defp set_status(data) do
    :dets.insert(@tab_name, {@tab_key, statuses_without_one(data.id) ++ [data]})
  end

  defp delete_status(id) do
    :dets.insert(@tab_name, {@tab_key, statuses_without_one(id)})
    # :dets.delete(@tab_name, @tab_key)
  end

  defp delete_without_ids() do
    :dets.insert(@tab_name, {@tab_key, Enum.reject(get_status(), &(is_nil(&1.id)))})
  end

  defp statuses_without_one(id) do
    statuses = get_status()
    case id do
      id when is_binary(id) -> Enum.reject(statuses, &(&1.id == id || is_nil(&1.id)))
      _ -> statuses
    end

  end

end
