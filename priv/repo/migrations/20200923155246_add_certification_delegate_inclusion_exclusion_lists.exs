defmodule Vae.Repo.Migrations.AddCertificationDelegateInclusionExclusionLists do
  use Ecto.Migration

  def change do
    create table(:certifications_delegates_inclusions) do
      add :certification_id, references(:certifications)
      add :delegate_id, references(:delegates)
    end
    create table(:certifications_delegates_exclusions) do
      add :certification_id, references(:certifications)
      add :delegate_id, references(:delegates)
    end
  end
end
