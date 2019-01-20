defmodule Mix.Tasks.Certification.Index do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Certification

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with true <- index_romes() do
      {:ok, "Well done !"}
    end
  end

  def index_romes() do
    objects = Enum.map(Certification.all(), &Certification.format_for_index/1) |> Enum.take(2)

    Algolia.save_objects("certifications", objects, id_attribute: :id)
  end
end
