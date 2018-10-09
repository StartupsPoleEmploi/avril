defmodule Vae.Repo.Migrations.AddTrackingColumnToJobSeerkers do
  use Ecto.Migration

  def change do
    alter table(:job_seekers) do
      add(:analytics, {:array, :jsonb}, default: [])
    end
  end
end
