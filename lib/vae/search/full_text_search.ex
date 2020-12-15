defmodule Vae.Search.FullTextSearch do
  import Ecto.Query

  alias Vae.{Certification, Profession, Repo}

  @searchable_entities [Certification, Profession]

  def run(module, search_string) when is_atom(module), do: run(from(e in module), search_string)

  def run(%Ecto.Query{} = query, search_string) do
    _run(query, Vae.String.parameterize(search_string))
  end

  # TODO: refacto cases
  defmacro join_certifications_materialized_view(search_string) do
    quote do
      fragment(
        """
        SELECT certifications_search.id AS id,
        ts_rank(
          certifications_search.document, plainto_tsquery(unaccent(?))
        ) AS rank,
        certifications_search.applications_count as count
        FROM certifications_search
        WHERE certifications_search.document @@ plainto_tsquery(unaccent(?))
        OR certifications_search.slug % ?
        """,
        ^unquote(search_string),
        ^unquote(search_string),
        ^unquote(search_string)
      )
    end
  end

  defmacro join_professions_materialized_view(search_string) do
    quote do
      fragment(
        """
        SELECT professions_search.id AS id,
        ts_rank(
          professions_search.document, plainto_tsquery(unaccent(?))
        ) AS rank
        FROM professions_search
        WHERE professions_search.document @@ plainto_tsquery(unaccent(?))
        OR professions_search.slug % ?
        """,
        ^unquote(search_string),
        ^unquote(search_string),
        ^unquote(search_string)
      )
    end
  end

  defp _run(query, ""), do: query
  defp _run(%Ecto.Query{
    from: %Ecto.Query.FromExpr{source: {_table_name, module}}
  } = query, "") when module not in @searchable_entities, do: query

  defp _run(%Ecto.Query{from: %Ecto.Query.FromExpr{source: {_table_name, Certification}}} = query, search_string) do
    from(elem in query,
      join: id_and_rank in join_certifications_materialized_view(search_string),
      on: id_and_rank.id == elem.id,
      order_by: [desc: id_and_rank.rank]
    )
  end

  defp _run(%Ecto.Query{from: %Ecto.Query.FromExpr{source: {_table_name, Profession}}} = query, search_string) do
    from(elem in query,
      join: id_and_rank in join_professions_materialized_view(search_string),
      on: id_and_rank.id == elem.id,
      order_by: [desc: elem.priority, desc: id_and_rank.rank]
    )
  end

  def refresh_materialized_view(module) when module in @searchable_entities,
    do: Repo.query("REFRESH MATERIALIZED VIEW CONCURRENTLY #{module_to_table(module)}_search;", [], timeout: :infinity)

  def module_to_table(module) do
    with %{__meta__: meta} <- struct(module), %{source: table} <- meta, do: table
  end
end