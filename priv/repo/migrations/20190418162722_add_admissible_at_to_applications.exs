defmodule Vae.Repo.Migrations.AddAdmissibleAtToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add(:admissible_at, :utc_datetime)
    end
  end
end
