defmodule Vae.Places.Cache do
  require Logger
  use GenServer

  @places_client Vae.Places.Client.Algolia
  @tab_name 'priv/tabs/#{Application.get_env(:vae, :places_ets_table_name)}.tab'

  # TODO: write a flush behavior

  ##############
  ### Server ###
  ##############

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: PlacesCache)
  end

  @impl true
  def init(_state) do
    :dets.open_file(@tab_name, [type: :set])
  end

  @impl true
  def handle_call({:get, postal_code}, _from, _state) do
    {:reply, get_or_insert(postal_code), nil}
  end

  # Unused?
  def handle_call({:get_city, nil, postal_code}, _from, _state) do
    {:reply, get_or_insert(postal_code), nil}
  end

  #############
  #### API ####
  #############

  defp get_or_insert(nil), do: nil

  defp get_or_insert(postal_code) do
    case :dets.lookup(@tab_name, postal_code) do
      [] -> insert(postal_code)
      [value] -> value
    end
  end

  defp insert(postal_code) do
    geoloc = @places_client.get_geoloc_from_postal_code(postal_code)
    :dets.insert(@tab_name, {postal_code, geoloc})
    {postal_code, geoloc}
  end
end
