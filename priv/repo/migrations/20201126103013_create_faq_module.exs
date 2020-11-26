defmodule Vae.Repo.Migrations.CreateFAQModule do
  use Ecto.Migration

  def change do
    create table(:faqs) do
      add :question, :text, null: false
      add :answer, :text, null: false
      add :order, :integer

      timestamps()
    end
  end
end
