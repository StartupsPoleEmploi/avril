defmodule Vae.Repo.Migrations.AddDescriptionToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add(:description, :text)
    end
  end
end
