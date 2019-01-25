defmodule Mix.Tasks.Rome.Index do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Rome

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with true <- index() do
      {:ok, "Well done !"}
    end
  end

  def index() do
    objects = Enum.map(Rome.all(), &Rome.format_for_index/1)

    Algolia.save_objects("rome", objects, id_attribute: :id)
  end
end
