defmodule Vae.Repo.Migrations.AddIsActiveToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :is_active, :boolean, default: true
    end
  end
end
