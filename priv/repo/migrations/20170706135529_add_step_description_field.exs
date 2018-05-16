defmodule Vae.Repo.Migrations.AddStepDescriptionField do
  use Ecto.Migration

  def change do
    alter table(:steps) do
      add :description, :string
    end
  end
end
