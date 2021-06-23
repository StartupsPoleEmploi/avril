defmodule Vae.Repo.Migrations.AddFieldsToResume do
  use Ecto.Migration

  def change do
    alter table(:resumes) do
      add :name, :string
      add :category, :string
    end
  end
end
