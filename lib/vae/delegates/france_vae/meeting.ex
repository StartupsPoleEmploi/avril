defmodule Vae.Delegates.FranceVae.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:academy_id, :string)
    field(:meeting_id, :integer)
    field(:place, :string)
    field(:address, :string)
    field(:target, :string)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
  end

  @fields ~w(academy_id meeting_id place address target start_date end_date)a

  def changeset(module, params) do
    module
    |> cast(params, @fields)
    |> validate_required([:academy_id, :meeting_id, :place, :address, :start_date, :end_date])
  end
end
