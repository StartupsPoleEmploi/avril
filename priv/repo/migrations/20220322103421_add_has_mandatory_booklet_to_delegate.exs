defmodule Vae.Repo.Migrations.AddHasMandatoryBookletToDelegate do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add :has_mandatory_booklet, :boolean, null: false, default: false
    end
  end
end
