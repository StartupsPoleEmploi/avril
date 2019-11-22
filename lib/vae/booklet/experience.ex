defmodule Vae.Booklet.Experience do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:title, :string)
    field(:company_name, :string)
    field(:full_address, :string)
    field(:job_industry, :string)
    field(:employment_type, :string)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:week_hour_duration, :integer)

    embeds_many :skills, Skill, primary_key: false do
      field(:description, :string)
    end
  end
end
