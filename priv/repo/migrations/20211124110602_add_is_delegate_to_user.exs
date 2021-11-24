defmodule Vae.Repo.Migrations.AddIsDelegateToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_delegate, :boolean, null: false, default: false
    end
  end
end
