defmodule Vae.Repo.Migrations.ChangeCoherenceToPow do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :email_confirmation_token, :string
      add :email_confirmed_at,       :utc_datetime
      # add :unconfirmed_email,        :string
    end

    create unique_index(:users, :email_confirmation_token)
  end

  def down do
    alter table(:users) do
      remove :email_confirmation_token
      remove :email_confirmed_at
      # remove :unconfirmed_email
    end
  end
end
