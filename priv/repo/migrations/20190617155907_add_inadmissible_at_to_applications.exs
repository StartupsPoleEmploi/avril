defmodule Vae.Repo.Migrations.AddInadmissibleAtToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add(:inadmissible_at, :utc_datetime)
    end
  end
end
