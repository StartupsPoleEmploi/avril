defmodule Vae.Repo.Migrations.AddJobSeekerEvents do
  use Ecto.Migration

  def change do
    add(:events, :map)
  end
end
