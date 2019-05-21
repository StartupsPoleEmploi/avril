defmodule Vae.Repo.Migrations.AddSlugToFields do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add(:slug, :string)
    end
    alter table(:professions) do
      add(:slug, :string)
    end
    alter table(:delegates) do
      add(:slug, :string)
    end
    alter table(:certifiers) do
      add(:slug, :string)
    end
    alter table(:romes) do
      add(:slug, :string)
    end
  end
end
