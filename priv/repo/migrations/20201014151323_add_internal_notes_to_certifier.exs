defmodule Vae.Repo.Migrations.AddInternalNotesToCertifier do
  use Ecto.Migration

  def change do
    alter table(:certifiers) do
      add :internal_notes, :text
    end

  end
end
