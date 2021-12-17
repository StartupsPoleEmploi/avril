defmodule Vae.JobSeeker do
  use VaeWeb, :model

  alias Vae.{Analytic, Event, Repo}
  alias __MODULE__

  schema "job_seekers" do
    field(:identifier, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:telephone, :string)
    field(:postal_code, :string)
    field(:experience, :map)
    field(:education_level, :string)

    field(:tracking_last_visit_at, :utc_datetime)

    field(:subscribed, :boolean, default: true)

    embeds_many(:events, Event, on_replace: :delete)
    embeds_many(:analytics, Analytic, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(%JobSeeker{} = job_seeker, attrs) do
    job_seeker
    |> cast(attrs, [
      :identifier,
      :first_name,
      :last_name,
      :email,
      :telephone,
      :postal_code,
      :experience,
      :education_level,
      :tracking_last_visit_at,
      :subscribed
    ])
  end

  def create_from_event(event) do
    event_changeset = Event.changeset(%Event{}, event)

    %JobSeeker{}
    |> changeset(%{email: event.email})
    |> put_embed(:events, [event_changeset])
  end

  def update_event_changeset(job_seeker, %{event: "unsub"} = event) do
    job_seeker
    |> change(subscribed: false)
    |> put_event(event, job_seeker.events)
  end

  def update_event_changeset(job_seeker, event) do
    job_seeker
    |> change()
    |> put_event(event, job_seeker.events)
  end

  def admissible(job_seeker) do
    update_event_changeset(
      job_seeker,
      %{
        type: "answer",
        event: "admissible",
        email: job_seeker.email,
        time: DateTime.utc_now() |> DateTime.to_unix()
      }
    )
  end

  def inadmissible(job_seeker) do
    update_event_changeset(
      job_seeker,
      %{
        type: "answer",
        event: "inadmissible",
        email: job_seeker.email,
        time: DateTime.utc_now() |> DateTime.to_unix()
      }
    )
  end

  def update_analytics_changeset(job_seeker, :new, analytic) do
    job_seeker
    |> change()
    |> put_embed(:analytics, [analytic | job_seeker.analytics])
  end

  def update_analytics_changeset(job_seeker, :old, analytic) do
    updated_analytics =
      job_seeker.analytics
      |> Enum.map(fn old_analytic ->
        case Date.compare(old_analytic.date, Date.utc_today()) do
          :eq -> analytic
          _ -> old_analytic
        end
      end)

    job_seeker
    |> change()
    |> put_embed(:analytics, updated_analytics)
  end

  def retrieve_by_email(email) do
    Repo.get_by(JobSeeker, email: email)
  end

  def init_analytic(job_seeker) do
    Enum.filter(job_seeker.analytics, fn analytic ->
      Date.compare(analytic.date, Date.utc_today()) == :eq
    end)
    |> case do
      [] ->
        {:new, Analytic.new()}

      [analytic | []] ->
        {:old, analytic}

      _ ->
        {:error, job_seeker}
    end
  end

  def list_from_events_month(%DateTime{} = current_date) do
    sql = """
      SELECT
        DISTINCT email,
        identifier,
        first_name,
        last_name,
        telephone,
        postal_code,
        experience,
        education_level,
        events
      FROM job_seekers, jsonb_array_elements(events) AS e
      WHERE (e->>'time')::timestamp BETWEEN $1 AND $2
    """

    start_date = get_first_day_of_previous_month(current_date)

    end_date = get_last_day_of_previous_month(current_date)

    Ecto.Adapters.SQL.query!(Repo, sql, [start_date, end_date])
  end

  defp get_first_day_of_previous_month(date) do
    Vae.Date.get_previous_month(date) |> Timex.beginning_of_month()
  end

  defp get_last_day_of_previous_month(date) do
    Vae.Date.get_previous_month(date) |> Timex.end_of_month()
  end

  defp put_event(changeset, event, events) do
    event_changeset = Event.changeset(%Event{}, event)

    changeset
    |> put_embed(:events, [event_changeset | events])
  end

  def fullname(job_seeker) do
    cond do
      job_seeker.first_name || job_seeker.last_name -> "#{job_seeker.first_name} #{job_seeker.last_name}" |> String.trim()
      true -> job_seeker.email
    end
  end

  def formatted_email(job_seeker) do
    cond do
      fullname(job_seeker) == job_seeker.email -> String.downcase(job_seeker.email)
      true -> {fullname(job_seeker), String.downcase(job_seeker.email)}
    end
  end

end
