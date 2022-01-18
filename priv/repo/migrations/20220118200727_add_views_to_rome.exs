defmodule Vae.Repo.Migrations.AddViewsToRome do
  use Ecto.Migration

  def change do
    alter table(:romes) do
      add :views, :integer, null: false, default: 0
    end
  end
end
