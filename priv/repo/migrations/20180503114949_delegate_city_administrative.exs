defmodule Vae.Repo.Migrations.DelegateCityAdministrative do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add(:city, :string)
      add(:administrative, :string)
    end
  end
end
