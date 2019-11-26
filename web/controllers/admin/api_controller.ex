defimpl Jason.Encoder, for: [Tuple] do
  def encode(data, _opts) when is_tuple(data) do
    {{y, m, d}, {h, min, s, ms}} = data
    Jason.encode!(NaiveDateTime.to_iso8601(%NaiveDateTime{
      year: y,
      month: m,
      day: d,
      hour: h,
      minute: min,
      second: s,
      microsecond: {ms, 0},
    }))
  end
end

defmodule ExAdmin.ApiController do
  use Vae.Web, :controller

  def get_status(conn, _params) do
    status = case GenServer.call(Status, :get) do
      nil -> nil
      map ->
        Vae.Map.map_values(map, fn {k, v} ->
          if (k |> Atom.to_string() |> String.ends_with?("_at")) && v do
            Timex.format!(v, "{ISO:Extended:Z}")
          else
            v
          end
        end)
    end
    json(conn, status)
  end

  def put_status(conn, %{
    "message" => status
  } = params) do
    :ok = GenServer.cast(Status, {:set, [
      message: status,
      level: params["level"] || "info",
      starts_at: (if not Vae.String.is_blank?(params["starts_at"]),
        do: Timex.parse!(params["starts_at"], "{ISO:Extended:Z}")),
      ends_at: (if not Vae.String.is_blank?(params["ends_at"]),
        do: Timex.parse!(params["ends_at"], "{ISO:Extended:Z}"))
    ]})
    json(conn, GenServer.call(Status, :get))
  end

  def delete_status(conn, _params) do
    :ok = GenServer.cast(Status, {:delete})
    json(conn, GenServer.call(Status, :get))
  end

  def sql(conn, %{"query" => query} = params) do
    query = apply(__MODULE__, :"#{query}_query", [
      (unless Vae.String.is_blank?(params["start_date"]), do: params["start_date"]),
      (unless Vae.String.is_blank?(params["start_date"]), do: params["end_date"])
    ])
    result = Ecto.Adapters.SQL.query!(Vae.Repo, query)
    json(conn, Map.from_struct(result))
  end

  def delegates_query(start_date, end_date) do
    """
    SELECT
      q.delegate_name,
      q.total,
      q.submitted,
      (100 * q.submitted / NULLIF(total, 0)) AS submitted_percent,
      q.admissible,
      q.inadmissible AS not_yet_admissible,
      (q.admissible + q.inadmissible) * 100 / NULLIF(q.submitted, 0) AS responded_percent,
      q.admissible * 100 / NULLIF(q.admissible + q.inadmissible, 0) AS admissible_percent
    FROM (
      SELECT delegates.name AS delegate_name,
      (#{applications_base_query("delegate", start_date, end_date)}) AS total,
      (#{applications_base_query("delegate", start_date, end_date)} AND applications.submitted_at IS NOT NULL) AS submitted,
      (#{applications_base_query("delegate", start_date, end_date)} AND applications.admissible_at IS NOT NULL) AS admissible,
      (#{applications_base_query("delegate", start_date, end_date)} AND applications.inadmissible_at IS NOT NULL) AS inadmissible
      FROM delegates
    ) q
    ORDER BY admissible_percent DESC NULLS LAST, total DESC
    """
  end

  def certifications_query(start_date, end_date) do
    """
    SELECT
      q.certification_name,
      q.total,
      q.submitted,
      (100 * q.submitted / NULLIF(total, 0)) AS submitted_percent,
      q.admissible,
      q.inadmissible,
      (q.admissible + q.inadmissible) * 100 / NULLIF(q.submitted, 0) AS responded_percent,
      (100 * q.admissible / NULLIF(q.admissible + q.inadmissible, 0)) AS admissible_percent
    FROM (
      SELECT CONCAT(certifications.acronym, ' ', certifications.label) AS certification_name,
      (#{applications_base_query("certification", start_date, end_date)}) AS total,
      (#{applications_base_query("certification", start_date, end_date)} AND applications.submitted_at IS NOT NULL) AS submitted,
      (#{applications_base_query("certification", start_date, end_date)} AND applications.admissible_at IS NOT NULL) AS admissible,
      (#{applications_base_query("certification", start_date, end_date)} AND applications.inadmissible_at IS NOT NULL) AS inadmissible
      FROM certifications
    ) q
    ORDER BY admissible_percent DESC NULLS LAST, total DESC
    """
  end

  defp applications_base_query(entity, nil, nil), do:
   "SELECT COUNT(*) FROM applications WHERE applications.#{entity}_id = #{entity}s.id"

  defp applications_base_query(entity, start_date, nil), do:
   "#{applications_base_query(entity)} AND applications.inserted_at >= '#{start_date}'::DATE"

  defp applications_base_query(entity, nil, end_date), do:
   "#{applications_base_query(entity)} AND applications.inserted_at <= '#{end_date}'::DATE"

  defp applications_base_query(entity, start_date, end_date), do:
   "#{applications_base_query(entity)} AND applications.inserted_at BETWEEN '#{start_date}'::DATE AND '#{end_date}'::DATE"

  defp applications_base_query(entity, start_date\\nil, end_date\\nil), do:
    applications_base_query(entity, start_date, end_date)

  defp date_parser(nil), do: nil
  defp date_parser(date_string), do: date_string
  # defp date_parser(date_string), do: Timex.parse!(date_string, "{YYYY}-{0M}-{0D}")
end