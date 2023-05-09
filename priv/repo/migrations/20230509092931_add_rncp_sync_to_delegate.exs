defmodule Vae.Repo.Migrations.AddRncpSyncToCertifier do
  use Ecto.Migration

  def change do
    alter table(:certifiers) do
      add :rncp_sync, :boolean, required: true, default: true
    end
  end
end
