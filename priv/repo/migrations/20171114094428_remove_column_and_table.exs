defmodule Vae.Repo.Migrations.RemoveColumnAndTable do
  use Ecto.Migration

  def change do
    drop table(:delegate_steps)
    drop table(:steps)
  end
end
