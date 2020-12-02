defmodule Vae.Repo.Migrations.RemoveUnusedUserFields do
  use Ecto.Migration

  def change do
    # All this data was moved to Vae.Identity embed
    alter table(:users) do
      remove :gender
      remove :email_confirmed_at
      remove :phone_number
      remove :postal_code
      remove :address1
      remove :address2
      remove :address3
      remove :address4
      remove :insee_code
      remove :country_code
      remove :city_label
      remove :country_label
      remove :birthday
      remove :birth_place
      remove :confirmation_token
      remove :confirmed_at
      remove :pe_connect_token
    end
  end
end
