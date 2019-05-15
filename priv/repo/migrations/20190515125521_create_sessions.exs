defmodule MyProject.Repo.Migrations.CreateSession do
  use Ecto.Migration

  def up do
    create table(:sessions) do
      add :token, :string, unique: true
      add :user_type, :string
      add :user_id, :string

      timestamps
    end

    create unique_index(:sessions, [:token])
    create index(:sessions, [:user_id])
  end

  def down do
    drop table(:sessions)
  end
end