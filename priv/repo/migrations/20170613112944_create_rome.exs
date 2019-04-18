defmodule Vae.Repo.Migrations.CreateRome do
  use Ecto.Migration

  def change do
    create table(:romes) do
      add(:code, :string)
      add(:label, :string)

      timestamps()
    end
  end
end
