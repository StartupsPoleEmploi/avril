defmodule Vae.Repo.Migrations.RemoveJobSeekers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :job_seeker_id, :integer
    end

    drop table(:job_seekers)
  end
end
