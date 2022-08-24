defmodule Vae.Repo.Migrations.AddRaisedAtToUserApplication do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add :raised_at, :utc_datetime
    end
  end
end
