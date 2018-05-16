defmodule Vae.Repo.Migrations.AddPeRomeUrl do
  use Ecto.Migration

  def change do
    alter table(:romes) do
      add :url, :string
    end
  end
end
