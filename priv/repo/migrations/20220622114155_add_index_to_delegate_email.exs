defmodule Vae.Repo.Migrations.AddIndexToDelegateEmail do
  use Ecto.Migration

  def change do
    create index(:delegates, [:email])
    create index(:delegates, [:secondary_email])
  end
end
