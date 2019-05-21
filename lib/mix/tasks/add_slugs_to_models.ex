defmodule Mix.Tasks.AddSlugsToModels do
  use Mix.Task

  require Logger

  import Mix.Ecto
  import Ecto.Query

  alias Vae.Repo
  alias Vae.{Certifier, Delegate, Certification, Profession, Rome}

  @shortdoc "Add Slugs to Models"
  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    Enum.each([Certification, Profession, Certifier, Rome], fn klass ->
      from(p in klass, where: is_nil(p.slug))
      |> Repo.all
      |> Enum.each(fn elem ->
        Repo.update(klass.changeset(elem))
      end)
    end)
  end

end
