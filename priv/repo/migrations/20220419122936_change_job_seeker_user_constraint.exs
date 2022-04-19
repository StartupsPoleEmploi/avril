defmodule Vae.Repo.Migrations.ChangeJobSeekerUserConstraint do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify(:job_seeker_id, references(:job_seekers, on_delete: :delete_all),
        from: references(:job_seekers, on_delete: :nothing))
    end
  end
end
