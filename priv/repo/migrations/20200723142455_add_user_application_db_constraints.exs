defmodule Vae.Repo.Migrations.AddUserApplicationDbConstraints do
  use Ecto.Migration

  def up do
    execute(
      "ALTER TABLE applications DROP CONSTRAINT applications_certification_id_fkey"
    )

    alter table(:applications) do
      modify(
        :certification_id,
        references(:certifications, on_delete: :nothing),
        null: false
      )
    end

    execute(
      "ALTER TABLE applications DROP CONSTRAINT applications_user_id_fkey"
    )

    alter table(:applications) do
      modify(
        :user_id,
        references(:users, on_delete: :delete_all),
        null: false
      )
    end
  end

  def down do
    execute(
      "ALTER TABLE applications DROP CONSTRAINT applications_user_id_fkey"
    )

    alter table(:applications) do
      modify(
        :user_id,
        references(:users, on_delete: :delete_all)
      )
    end

    execute(
      "ALTER TABLE applications DROP CONSTRAINT applications_certification_id_fkey"
    )

    alter table(:applications) do
      modify(
        :certification_id,
        references(:certifications, on_delete: :nilify_all)
      )
    end
  end
end
