defmodule Mix.Tasks.Delegate.Index do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Delegate

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with true <- index_delegates() do
      {:ok, "Well done !"}
    end
  end

  def index_delegates() do
    "delegate"
    |> Algolia.save_objects(Delegate.all() |> Enum.map(&format_for_index/1), id_attribute: :id)
  end

  def format_for_index(delegate) do
    delegate
    |> Map.take(Delegate.__schema__(:fields))
    |> Map.put(:_geoloc, delegate.geolocation["_geoloc"])
  end
end
