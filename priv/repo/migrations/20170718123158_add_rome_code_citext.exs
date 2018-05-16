defmodule Vae.Repo.Migrations.AddRomeCodeCitext do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext"

    alter table(:romes) do
      modify :code, :citext
    end
  end
end
