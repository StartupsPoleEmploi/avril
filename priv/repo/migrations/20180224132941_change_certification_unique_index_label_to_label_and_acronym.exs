defmodule Vae.Repo.Migrations.ChangeCertificationUniqueIndexLabelToLabelAndAcronym do
  use Ecto.Migration

  def change do
    drop index(:certifications, [:label])
    create unique_index(:certifications, [:acronym, :label])
  end
end
