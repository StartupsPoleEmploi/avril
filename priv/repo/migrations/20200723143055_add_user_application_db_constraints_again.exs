defmodule Vae.Repo.Migrations.AddUserApplicationDbConstraintsAgain do
  use Ecto.Migration

  def change do
    drop unique_index(:applications, [:user_id, :delegate_id, :certification_id], name: :application_unicity_index)
    create unique_index(:applications, [:user_id, :certification_id], name: :application_unicity_index)
  end
end
