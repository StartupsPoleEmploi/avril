defmodule Vae.Repo.Migrations.ProcessesWithSteps do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      add :step_1, :text
      add :step_2, :text
      add :step_3, :text
      add :step_4, :text
      add :step_5, :text
      add :step_6, :text
      add :step_7, :text
      add :step_8, :text
    end
  end
end
