defmodule Vae.Repo.Migrations.DropAndRenameWrongFieldsInApplications do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:skills)
      remove(:experiences)
      remove(:proven_experiences)
    end

    rename(table(:users), :skills_2, to: :skills)
    rename(table(:users), :experiences_2, to: :experiences)
    rename(table(:users), :proven_experiences_2, to: :proven_experiences)
  end
end
