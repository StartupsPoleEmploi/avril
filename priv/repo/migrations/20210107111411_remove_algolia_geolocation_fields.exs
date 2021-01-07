defmodule Vae.Repo.Migrations.RemoveAlgoliaGeolocationFields do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      remove :geolocation, :map
    end

    alter table(:job_seekers) do
      remove :geolocation, :map
    end
  end
end
