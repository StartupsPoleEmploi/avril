defmodule Vae.Repo.Migrations.AddSearchCapabilities do
  use Ecto.Migration

  def up do
    execute(
      """
      CREATE EXTENSION IF NOT EXISTS unaccent
      """
    )
    execute(
      """
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      """
    )

    create_materialized_view("certifications")
    create_materialized_view("professions")

  end

  def down do
    remove_materialized_view("certifications")
    remove_materialized_view("professions")
  end

  defp create_materialized_view(table_name) do
    {select_clause, join_clause} = applications_join(table_name)

    execute(
      """
      CREATE MATERIALIZED VIEW #{table_name}_search AS
      SELECT
        #{table_name}.id AS id,
        #{table_name}.slug AS slug,
        #{select_clause}
        (
        setweight(to_tsvector(#{table_name}.slug), 'A')
        ) AS document
      FROM #{table_name}
      #{join_clause}
      #{is_active_filter(table_name)}
      GROUP BY #{table_name}.id
      """
    )
    # to support full-text searches
    create index("#{table_name}_search", ["document"], using: :gin)

    # to support substring title matches with ILIKE
    execute("CREATE INDEX #{table_name}_search_index ON #{table_name}_search USING gin (slug gin_trgm_ops)")

    # to support updating CONCURRENTLY
    create unique_index("#{table_name}_search", [:id])

  end

  defp remove_materialized_view(table_name) do
    execute("""
      DROP MATERIALIZED VIEW #{table_name}_search
    """)
  end

  defp applications_join("certifications") do
    {
      "count(applications.id) AS applications_count,",
      "LEFT JOIN applications ON applications.certification_id = certifications.id"
    }
  end

  defp applications_join(_), do: {"", ""}

  defp is_active_filter("certifications") do
    "WHERE certifications.is_active"
  end

  defp is_active_filter(_), do: ""

end
