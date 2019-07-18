defmodule Vae.Repo.Migrations.AddMeetingInfoToApplication do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add(:meeting, :map)
    end
  end
end
