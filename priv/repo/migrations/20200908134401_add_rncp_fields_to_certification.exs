defmodule Vae.Repo.Migrations.AddRncpFieldsToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :activity_area, :string
      add :accessible_job_type, :string
      add :activities, :text
      add :abilities, :text
      add :newer_certification_id, references(:certifications)

      remove :description, :string
    end
  end
end
