defmodule Vae.Repo.Migrations.AddCertificationDelegateAssociationToView do
  use Ecto.Migration

  def up do
    drop table("certifications_delegates")

    execute(
      """
      CREATE VIEW certifications_delegates AS (
        SELECT c.id AS certification_id, d.id AS delegate_id
        FROM certifications c
        INNER JOIN certifier_certifications cc
        ON cc.certification_id = c.id
        INNER JOIN certifiers_delegates cd
        ON cd.certifier_id = cc.certifier_id
        INNER JOIN delegates d
        ON cd.delegate_id = d.id
        WHERE NOT EXISTS (
          SELECT 1 FROM certifications_delegates_exclusions cde
          WHERE cde.delegate_id = d.id AND cde.certification_id = c.id
        )
        UNION (
          SELECT cdi.certification_id AS certification_id, cdi.delegate_id AS delegate_id
          FROM certifications_delegates_inclusions cdi
        )
      )
      """
    )

  end

  def down do
    execute("DROP VIEW certifications_delegates")

    create table(:certifications_delegates) do
      add :certification_id, references(:certifications)
      add :delegate_id, references(:delegates)
    end
  end
end
