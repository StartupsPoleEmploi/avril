defmodule Vae.Repo.Migrations.AddConfirmableAndRememberableFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:confirmation_token, :string)
      add(:confirmed_at, :utc_datetime)
      add(:confirmation_sent_at, :utc_datetime)
      add(:unconfirmed_email, :string)
      add(:remember_created_at, :utc_datetime)
    end
  end
end
