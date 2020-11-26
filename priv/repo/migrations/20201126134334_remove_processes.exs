defmodule Vae.Repo.Migrations.RemoveProcesses do
  use Ecto.Migration
  import Logger

  def up do
    alter table(:delegates) do
      remove(:process_id)
      remove(:step_1)
      remove(:step_2)
      remove(:step_3)
      remove(:step_5)
      remove(:step_6)
      remove(:step_7)
      remove(:step_8)
    end

    Ecto.Adapters.SQL.query!(
      Vae.Repo, "DROP TABLE processes,processes_steps,steps CASCADE;")

  end

  def down do
    Logger.warn("Irreversible migration :(")
  end
end
