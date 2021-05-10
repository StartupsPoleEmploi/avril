defmodule Vae.Repo.Migrations.ChangeCertificationDelegateViewToMaterializedView do
  use Ecto.Migration

  def up do
    execute("DROP VIEW certifications_delegates")

    execute(
      """
      CREATE MATERIALIZED VIEW certifications_delegates AS (
        SELECT DISTINCT cc.certification_id AS certification_id, cd.delegate_id AS delegate_id
        FROM certifier_certifications cc
        INNER JOIN certifiers_delegates cd
        ON cd.certifier_id = cc.certifier_id
        WHERE NOT EXISTS (
          SELECT 1 FROM certifications_delegates_exclusions cde
          WHERE cde.delegate_id = cd.delegate_id AND cde.certification_id = cc.certification_id
        )
        UNION (
          SELECT cdi.certification_id AS certification_id, cdi.delegate_id AS delegate_id
          FROM certifications_delegates_inclusions cdi
        )
      )
      """
    )

    execute(
      """
      CREATE OR REPLACE FUNCTION refresh_certifications_delegates_mat_view()
      RETURNS TRIGGER language plpgsql
      AS $$
      begin
          REFRESH MATERIALIZED VIEW certifications_delegates;
          return null;
      end $$;
      """
    )

    [
      "certifier_certifications",
      "certifiers_delegates",
      "certifications_delegates_exclusions",
      "certifications_delegates_inclusions"
    ] |> Enum.map(fn table_name ->
      execute(
        """
        CREATE TRIGGER refresh_certifications_delegates_mat_view
        AFTER insert OR update OR delete OR truncate
        ON #{table_name} FOR EACH STATEMENT
        EXECUTE PROCEDURE refresh_certifications_delegates_mat_view();
        """
      )
    end)
  end

  def down do
    execute("DROP MATERIALIZED VIEW certifications_delegates")
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
end
