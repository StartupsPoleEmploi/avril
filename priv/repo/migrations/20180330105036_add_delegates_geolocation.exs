defmodule Vae.Repo.Migrations.AddDelegatesGeolocation do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add(:geolocation, :map)
    end
  end
end
