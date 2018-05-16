defmodule Vae.ProfessionView do
  use Vae.Web, :view
  use Scrivener.HTML

  alias Vae.Repo.NewRelic, as: Repo

  def certifications_count(rome) do
    rome
    |> Ecto.assoc(:certifications)
    |> Repo.aggregate(:count, :id)
  end

end
