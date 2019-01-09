defmodule Mix.Tasks.Rome.Index do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Rome

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with true <- index_romes() do
      {:ok, "Well done !"}
    end
  end

  def index_romes() do
    "rome"
    |> Algolia.save_objects(Rome.all() |> Enum.map(&Rome.format_for_index/1), id_attribute: :id)
  end
end
