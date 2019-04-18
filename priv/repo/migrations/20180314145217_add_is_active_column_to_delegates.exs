defmodule Vae.Repo.Migrations.AddIsActiveColumnToDelegates do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add(:is_active, :boolean, default: false)
    end
  end
end
