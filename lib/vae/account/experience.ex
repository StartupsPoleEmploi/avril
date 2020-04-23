defmodule Vae.Experience do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:company, :string)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:is_current_job, :boolean)
    field(:is_abroad, :boolean)
    field(:label, :string)
    field(:duration, :integer)
  end

  @fields ~w(company start_date end_date is_abroad label duration)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def unique_key(experience) do
    "#{experience.company}-#{experience.label}-#{
      Vae.Date.format_for_unique_key(experience.start_date)
    }-#{Vae.Date.format_for_unique_key(experience.end_date)}"
  end
end
