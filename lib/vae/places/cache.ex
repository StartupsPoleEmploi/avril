defmodule Vae.Places.Cache do
  require Logger
  use GenServer
  alias Vae.Places.Client.Algolia

  @places_ets_table_name :places_dev

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, Map.new(), name: PlacesCache)
  end

  @impl true
  def init(state) do
    PersistentEts.new(@places_ets_table_name, "priv/tabs/#{@places_ets_table_name}.tab", [
      :named_table,
      :public
    ])

    {:ok, state}
  end

  # ------------#
  #   Server   #
  # ------------#

  @impl true
  def handle_call({:get, nil}, _from, state), do: {:reply, nil, state}

  @impl true
  def handle_call({:get, postal_code}, _from, state) do
    {value, new_state} =
      case Map.get_lazy(state, postal_code, fn -> get_or_insert(postal_code) end) do
        {:new, {_key, value}} ->
          {value, Map.put(state, postal_code, value)}

        {:old, {_key, value}} ->
          {value, state}

        value when value != %{} ->
          {value, state}

        _ ->
          Logger.error("Error when attempting to retrieve the postal code: #{postal_code}")
          {nil, state}
      end

    {:reply, value, new_state}
  end

  def handle_call({:get_city, nil, nil}, _from, state), do: {:reply, nil, state}

  def handle_call({:get_city, nil, postal_code}, _from, state),
    do: {:reply, get_geoloc_from_postal_code(postal_code), state}

  def handle_call({:get_city, city}, _from, state) do
    {:reply, Algolia.get_geoloc_from_city(city), state}
  end

  # -----------#
  #    API    #
  # -----------#

  def get_geoloc_from_city(city) do
    GenServer.call(PlacesCache, {:get_city, city}, 10_000)
  end

  def get_geoloc_from_postal_code(postal_code) do
    GenServer.call(PlacesCache, {:get, postal_code}, 10_000)
  end

  defp get_or_insert(postal_code) do
    case :ets.lookup(@places_ets_table_name, postal_code) do
      [] ->
        {:new, insert(postal_code)}

      [value] ->
        {:old, value}
    end
  end

  defp insert(postal_code) do
    geoloc = Algolia.get_geoloc_from_postal_code(postal_code)
    :ets.insert(@places_ets_table_name, {postal_code, geoloc})
    {postal_code, geoloc}
  end
end
