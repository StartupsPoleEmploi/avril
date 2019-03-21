defmodule Vae.Repo.Migrations.AddPEConnectFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:is_admin, :boolean, default: false)
      add(:postal_code, :string)
      add(:address1, :string)
      add(:address2, :string)
      add(:address3, :string)
      add(:address4, :string)
      add(:insee_code, :string)
      add(:country_code, :string)
      add(:city_label, :string)
      add(:country_label, :string)
      add(:pe_id, :string)
      add(:pe_connect_token, :string)
      add(:job_seeker_id, references(:job_seekers))
      add(:skills, {:array, :jsonb}, default: [])
      add(:experiences, {:array, :jsonb}, default: [])
    end
  end
end
