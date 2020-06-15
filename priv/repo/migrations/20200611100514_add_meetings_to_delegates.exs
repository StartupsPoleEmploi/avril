defmodule Vae.Repo.Migrations.AddMeetingsToDelegates do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add(:meetings, {:array, :jsonb}, default: [])
    end
  end
end
