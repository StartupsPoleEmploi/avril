# defimpl Jason.Encoder, for: [Tuple] do
#   def encode(data, _opts) when is_tuple(data) do
#     {{y, m, d}, {h, min, s, ms}} = data

#     Jason.encode!(
#       NaiveDateTime.to_iso8601(%NaiveDateTime{
#         year: y,
#         month: m,
#         day: d,
#         hour: h,
#         minute: min,
#         second: s,
#         microsecond: {ms, 0}
#       })
#     )
#   end
# end

defmodule VaeWeb.StatsController do
  use VaeWeb, :controller

  def sql(conn, %{"query" => query} = params) do
    start_date = Vae.String.blank_is_nil(params["start_date"])
    end_date = Vae.String.blank_is_nil(params["end_date"])
    limit = case Vae.String.blank_is_nil(params["limit"]) do
      nil -> nil
      number -> String.to_integer(number)
    end

    query =
      apply(__MODULE__, :"#{query}_query", [
        start_date,
        end_date,
        limit
      ])

    result = Ecto.Adapters.SQL.query!(Vae.Repo, query)

    json(
      conn,
      Map.merge(
        Map.from_struct(result),
        %{
          query: %{
            start_date: start_date,
            end_date: end_date,
            limit: limit
          }
        }
      )
    )
  end

  def applications_query(start_date, end_date, _limit) do
    # Check Vae.Repo.Migrations.ChangeApplicationStatus
    # to see status(application) and booklet_status(application) SQL function definition

    """
    SELECT
      to_char(applications.inserted_at, 'IYYY-IW') AS week_number,
      (case when applications.submitted_at is not NULL then '1-submitted' else '0-created' end) AS status,
      count(applications.*) as count
    FROM applications
    #{where_applications_date_filter(start_date, end_date)}
    GROUP BY week_number, status
    ORDER BY week_number, status;
    """
  end

  def delegates_query(start_date, end_date, limit) do
    """
    SELECT
      q.delegate_name,
      q.total,
      q.submitted
    FROM (
      SELECT delegates.name AS delegate_name,
      (#{applications_base_query("delegate", start_date, end_date)}) AS total,
      (#{applications_base_query("delegate", start_date, end_date)} AND applications.submitted_at IS NOT NULL) AS submitted
      FROM delegates
    ) q
    ORDER BY q.total DESC NULLS LAST
    #{limit_if_present(limit)}
    """
  end

  def certifications_query(start_date, end_date, limit) do
    """
    SELECT
      q.certification_name,
      q.total,
      q.submitted
    FROM (
      SELECT CONCAT(certifications.acronym, ' ', certifications.label) AS certification_name,
      (#{applications_base_query("certification", start_date, end_date)}) AS total,
      (#{applications_base_query("certification", start_date, end_date)} AND applications.submitted_at IS NOT NULL) AS submitted
      FROM certifications
    ) q
    ORDER BY q.total DESC NULLS LAST
    #{limit_if_present(limit)}
    """
  end

  defp where_applications_date_filter(nil, nil), do: ""

  defp where_applications_date_filter(start_date, end_date),
    do: "WHERE applications.inserted_at #{between_dates_to_sql(start_date, end_date)}"

  defp applications_base_query(entity),
    do: "SELECT COUNT(*) FROM applications WHERE applications.#{entity}_id = #{entity}s.id"

  defp applications_base_query(entity, nil, nil), do: applications_base_query(entity)

  defp applications_base_query(entity, start_date, end_date),
    do:
      "#{applications_base_query(entity)} AND applications.inserted_at #{
        between_dates_to_sql(start_date, end_date)
      }"

  defp between_dates_to_sql(start_date, nil),
    do: ">= '#{start_date}'::DATE"

  defp between_dates_to_sql(nil, end_date),
    do: "<= '#{end_date}'::DATE"

  defp between_dates_to_sql(start_date, end_date),
    do: "BETWEEN '#{start_date}'::DATE AND '#{end_date}'::DATE"

  def limit_if_present(limit) when is_number(limit), do: "LIMIT #{limit}"
  def limit_if_present(limit), do: ""
end
