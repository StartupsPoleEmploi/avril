defmodule Vae.JobSeeker do
  use Vae.Web, :model

  alias Ecto.Changeset

  schema "job_seekers" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:telephone, :string)
    field(:experience_level, :string)
    field(:education_level, :string)

    field(:created_at, :date)
    field(:last_visit_at, :date)
    field(:sent_activation_email_at, :date)

    timestamps()
  end
end
