defmodule Vae.Repo.Migrations.AddAcademyIdsToDelegates do
  use Ecto.Migration
  alias Vae.{Certifier, Delegate}

  def change do
    alter table(:delegates) do
      add(:academy_id, :string)
    end
  end
end
