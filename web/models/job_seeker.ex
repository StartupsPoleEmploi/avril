defmodule Vae.JobSeeker do
  use Vae.Web, :model
  alias Vae.JobSeeker

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
    field(:tracking_email_sent_activation_email_at, :utc_datetime)

    field(:subscribed, :boolean, default: true)
    field(:geolocation, :map)

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
      :tracking_sent_activation_email_at
    ])
  end
end
