defmodule Vae.Repo.Migrations.AddDeleteAtToMeeting do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      add :deleted_at, :utc_datetime
    end

  end
end
