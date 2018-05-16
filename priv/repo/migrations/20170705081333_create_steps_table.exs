defmodule Vae.Repo.Migrations.CreateStepsTable do
  use Ecto.Migration

  def change do
    create table(:steps) do
      add :facultative, :boolean, default: false
      add :index, :integer, null: false
      add :title, :string, null: false
      add :processes, {:array, :map}, default: []
      add :annexes, {:array, :map}, default: []

      add :delegate_id, references(:delegates)

      timestamps()
    end

    create table(:delegate_steps, primary_key: false) do
      add :delegate_id, references(:delegates)
      add :step_id, references(:steps)
    end
  end
end
