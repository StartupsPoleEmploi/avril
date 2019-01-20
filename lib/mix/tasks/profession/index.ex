defmodule Mix.Tasks.Profession.Index do
  use Mix.Task

  import Mix.Ecto
  import Ecto.Query, only: [from: 2]

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
    # TODO: Remove this when no more limitations from algolia 
    query =
      from(p in Profession,
        join: r in "rome_certifications",
        on: p.rome_id == r.rome_id,
        group_by: p.id,
        select: p
      )

    professions = Repo.all(query)

    objects =
      professions
      |> Repo.preload(:rome)
      |> Enum.map(&Profession.format_for_index/1)

    Algolia.save_objects("professions", objects, id_attribute: :id)
  end
end
