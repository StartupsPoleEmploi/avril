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
    field(:week_hours_duration, :integer)

    embeds_many :skills, Skill, primary_key: false, on_replace: :delete do
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end
  end

  @fields ~w(
    title
    company_name
    full_address
    job_industry
    employment_type
    start_date
    end_date
    week_hours_duration
  )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:skills)
  end
end
