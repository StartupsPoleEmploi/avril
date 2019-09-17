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
    json(conn, GenServer.call(Status, :get))
    |> Vae.Map.map_values(fn {k, v} ->
        if k |> Atom.to_string() |> String.ends_with?("_at") do
          Timex.format!(v, "{ISO:Extended:Z}")
        else
          v
        end
      end)
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

  def sql(conn, %{"query" => query}) do
    query = apply(__MODULE__, :"#{query}_query", [])
    result = Ecto.Adapters.SQL.query!(Vae.Repo, query)
    json(conn, Map.from_struct(result))
  end

  def delegates_query() do
    """
    select
      q.certifier_name,
      q.delegate_name,
      q.total,
      q.submitted,
      (100 * q.submitted / NULLIF(total, 0)) as submitted_percent,
      q.admissible,
      q.inadmissible,
      (q.admissible + q.inadmissible) * 100 / NULLIF(q.submitted, 0) as responded_percent,
      q.admissible * 100 / NULLIF(q.admissible + q.inadmissible, 0) as admissible_percent
    from (
      select certifiers.name as certifier_name, delegates.name as delegate_name,
      (select count(*) from applications where applications.delegate_id = delegates.id) as total,
      (select count(*) from applications where applications.delegate_id = delegates.id  and applications.submitted_at IS NOT NULL) as submitted,
      (select count(*) from applications where applications.delegate_id = delegates.id  and applications.admissible_at IS NOT NULL) as admissible,
      (select count(*) from applications where applications.delegate_id = delegates.id  and applications.inadmissible_at IS NOT NULL) as inadmissible
      from delegates
      inner join certifiers_delegates on delegates.id = certifiers_delegates.delegate_id
      inner join certifiers on certifiers_delegates.certifier_id = certifiers.id
    ) q
    order by admissible_percent desc NULLS LAST, total desc
    """
  end

  def certifications_query() do
    """
    select
      q.certifier_name,
      q.certification_name,
      q.total,
      q.submitted,
      (100 * q.submitted / NULLIF(total, 0)) as submitted_percent,
      q.admissible,
      q.inadmissible,
      (q.admissible + q.inadmissible) * 100 / NULLIF(q.submitted, 0) as responded_percent,
      (100 * q.admissible / NULLIF(q.admissible + q.inadmissible, 0)) as admissible_percent
    from (
      select certifiers.name as certifier_name, CONCAT(certifications.acronym, certifications.label) as certification_name,
      (select count(*) from applications where applications.certification_id = certifications.id) as total,
      (select count(*) from applications where applications.certification_id = certifications.id  and applications.submitted_at IS NOT NULL) as submitted,
      (select count(*) from applications where applications.certification_id = certifications.id  and applications.admissible_at IS NOT NULL) as admissible,
      (select count(*) from applications where applications.certification_id = certifications.id  and applications.inadmissible_at IS NOT NULL) as inadmissible
      from certifications
      inner join certifier_certifications on certifications.id = certifier_certifications.certification_id
      inner join certifiers on certifier_certifications.certifier_id = certifiers.id
    ) q
    order by admissible_percent desc NULLS LAST, total desc
    """
  end

end