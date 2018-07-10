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

      add(:register_at, :utc_datetime)
      add(:last_visit_at, :utc_datetime)
      add(:sent_activation_email_at, :utc_datetime)

      add(:subscribed, :boolean)

      timestamps()
    end
    create unique_index(:job_seekers, [:email])
  end
end
