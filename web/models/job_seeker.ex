defmodule Vae.JobSeeker do
  use Vae.Web, :model

  schema "job_seekers" do
    field(:identifier, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:telephone, :string)
    field(:postal_code, :string)
    field(:experience_level, :string)
    field(:education_level, :string)

    field(:tracking_last_visit_at, :date)
    field(:tracking_sent_activation_email_at, :date)

    field(:subscribed, :boolean, default: true)
    field(:geolocation, :map)

    timestamps()
  end
end
