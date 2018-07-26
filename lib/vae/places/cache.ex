defmodule Vae.Places.Cache do
  require Logger
  use GenServer

  @name PlacesCache

  @places_ets_table_name Application.get_env(:vae, :places_ets_table_name)
  @places_client Application.get_env(:vae, :places_client)

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, Map.new(), name: @name)
  end

  @impl true
  def init(state) do
    PersistentEts.new(@places_ets_table_name, "#{@places_ets_table_name}.tab", [:named_table])
    {:ok, state}
  end

  # -----------#
  #    API    #
  # -----------#   

  def get_geoloc_from_postal_code(postal_code) do
    GenServer.call(PlacesCache, {:get, postal_code}, 10_000)
  end

  # ------------#
  #   Server   #
  # ------------#   

  @impl true
  def handle_call({:get, nil}, _from, state), do: {:reply, nil, state}

  @impl true
  def handle_call({:get, postal_code}, _from, state) do
    {value, new_state} =
      case Map.get_lazy(state, postal_code, fn -> get_or_store(postal_code) end) do
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

  defp get_or_store(postal_code) do
    case :ets.lookup(@places_ets_table_name, postal_code) do
      [] ->
        {:new, insert(postal_code)}

      [value] ->
        {:old, value}
    end
  end

  def insert(postal_code) do
    geoloc = @places_client.get_geoloc_from_postal_code(postal_code)
    :ets.insert(@places_ets_table_name, {postal_code, geoloc})
    {postal_code, geoloc}
  end
end
