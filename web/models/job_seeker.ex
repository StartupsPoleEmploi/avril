defmodule Vae.JobSeeker do
  use Vae.Web, :model

  alias Vae.{Event, JobSeeker}
  alias Vae.Repo

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
    field(:geolocation, :map)

    embeds_many(:events, Event, on_replace: :delete)

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
      :subscribed,
      :geolocation
    ])
  end

  def create_from_event(event) do
    event_changeset = Event.changeset(%Event{}, event)

    %__MODULE__{}
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

  def retrieve_by_email(email) do
    Repo.get_by(__MODULE__, email: email)
  end

  defp put_event(changeset, event, events) do
    event_changeset = Event.changeset(%Event{}, event)

    changeset
    |> put_embed(:events, [event_changeset | events])
  end
end
