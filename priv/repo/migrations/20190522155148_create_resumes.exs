defmodule Vae.Repo.Migrations.CreateResumes do
  use Ecto.Migration

  def change do
    create table(:resumes) do
      add :filename, :string
      add :content_type, :string
      add :url, :string
      add :application_id, references(:applications, on_delete: :nothing)

      timestamps()
    end

    create index(:resumes, [:application_id])
  end
end
