defmodule Vae.Repo.Migrations.AddExternalNotesToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :external_notes, :text
    end
  end
end
