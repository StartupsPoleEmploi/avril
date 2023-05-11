defmodule Vae.Repo.Migrations.AddSearchableCertificationMaterializedView do
  use Ecto.Migration

  def up do
    execute(
      """
      DROP FUNCTION refresh_certifications_delegates_mat_view() CASCADE;
      """
    )

    execute(
      """
      CREATE MATERIALIZED VIEW searchable_certifications AS (
        SELECT * FROM certifications
        WHERE certifications.is_active
        AND EXISTS (
          SELECT null FROM delegates
          INNER JOIN certifications_delegates
          ON delegates.id = certifications_delegates.delegate_id
          WHERE delegates.is_active
          AND certifications_delegates.certification_id = certifications.id
        )
      )
      """
    )

  end

  def down do
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

    execute("DROP MATERIALIZED VIEW searchable_certifications")
  end
end
