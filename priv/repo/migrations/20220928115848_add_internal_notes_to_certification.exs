defmodule Vae.Repo.Migrations.AddInternalNotesToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :internal_notes, :text
    end
  end
end
