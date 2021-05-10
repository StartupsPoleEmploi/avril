defmodule Vae.Repo.Migrations.AddIsPRCToDelegate do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add(:is_prc, :boolean)
    end
  end
end
