defmodule Vae.Repo.Migrations.RemoveDelegatesIdOnSteps do
  use Ecto.Migration

  def change do
    alter table(:steps) do
      remove :delegate_id
    end
  end
end
