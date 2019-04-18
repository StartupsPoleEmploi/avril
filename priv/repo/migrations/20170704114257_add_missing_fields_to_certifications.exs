defmodule Vae.Repo.Migrations.AddMissingFieldsToCertifications do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add(:acronym, :string)
      add(:level, :integer)
    end
  end
end
