defmodule Vae.Repo.Migrations.AddJuryVaeCompositionToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :jury_composition, :text
    end
  end
end
