defmodule Vae.Repo.Migrations.AddEventsMapToJobSeeker do
  use Ecto.Migration

  def change do
    alter table(:job_seekers) do
      add(:events, :map)
    end
  end
end
