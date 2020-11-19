defmodule Vae.Repo.Migrations.AddAddressLabelToDelegate do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add(:address_name, :string)
    end
  end
end
