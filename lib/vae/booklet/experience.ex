defmodule Vae.Booklet.Experience do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:uuid, :string)
    field(:title, :string)
    field(:company_name, :string)
    field(:full_address, :string)
    field(:job_industry, :string)
    field(:employment_type, :string)

    embeds_many :skills, Skill, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end

    embeds_many :periods, Period, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:start_date, :date)
      field(:end_date, :date)
      field(:week_hours_duration, :integer)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:start_date, :end_date, :week_hours_duration])
      end
    end
  end

  @fields ~w(
    uuid
    title
    company_name
    full_address
    job_industry
    employment_type
  )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:skills)
    |> cast_embed(:periods)
  end
end
