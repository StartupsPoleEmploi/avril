defmodule Vae.PlacesLoadBalancer do
  require Logger

  use Agent

  @name __MODULE__

  @places_client Application.get_env(:vae, :places_client)

  @apis Application.get_env(:vae, :algolia_places_apis)

  def start_link() do
    Logger.info("Start load balancer")
    Agent.start_link(fn -> poll() end, name: @name)
  end

  def get_index(), do: Agent.get(@name, & &1)

  def update_index(), do: Agent.update(@name, &poll/0)

  def poll() do
    Logger.info("Start polling to retrieve available indexes from places")

    {index_of_selected_app, _usage} =
      @apis
      |> Stream.with_index()
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(&@places_client.get/1)
      |> Enum.to_list()
      |> Enum.min_by(&elem(&1, 1))

    index =
      Enum.at(@apis, index_of_selected_app)
      |> extract_api_search_credentials()

    Logger.info("End of polling indexes from places, selected index: #{elem(index, 0)}")

    index
  end

  defp extract_api_search_credentials({app_id, %{search: search_api_key}}),
    do: {app_id, search_api_key}
end
