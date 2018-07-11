defmodule Vae.Repo.Migrations.AddJobSeeker do
  use Ecto.Migration

  def change do
    create table(:job_seekers) do
      add(:identifier, :string)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:email, :string)
      add(:telephone, :string)
      add(:postal_code, :string)
      add(:experience_level, :string)
      add(:education_level, :string)

      add(:tracking_last_visit_at, :utc_datetime)
      add(:tracking_sent_activation_email_at, :utc_datetime)

      add(:subscribed, :boolean)
      add(:geolocation, :map)

      timestamps()
    end

    create(unique_index(:job_seekers, [:email]))
  end
end
