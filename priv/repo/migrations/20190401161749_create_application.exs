defmodule Vae.Repo.Migrations.CreateApplication do
  use Ecto.Migration

  def change do
    create table(:applications) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :delegate_id, references(:delegates, on_delete: :nilify_all)
      add :certification_id, references(:certifications, on_delete: :nilify_all)
      add :submitted_at, :utc_datetime

      timestamps()
    end

    create index(:applications, [:user_id])
    create index(:applications, [:delegate_id])
    create index(:applications, [:certification_id])
    create unique_index(:applications, [:user_id, :delegate_id, :certification_id], name: :application_unicity_index)

  end
end
