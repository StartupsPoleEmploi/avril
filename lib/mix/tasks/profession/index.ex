defmodule Mix.Tasks.Profession.Index do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Profession

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with true <- index() do
      {:ok, "Well done !"}
    end
  end

  def index() do
    objects =
      Profession.all()
      # TODO remove when no limit
      |> Enum.take(8000)
      |> Repo.preload(:rome)
      |> Enum.map(&Profession.format_for_index/1)

    Algolia.save_objects("professions", objects, id_attribute: :id)
  end
end
