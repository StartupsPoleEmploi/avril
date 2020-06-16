defmodule Vae.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:academy_id, :string)
    field(:address, :string)
    field(:city, :string)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:meeting_id, :string)
    field(:place, :string)
    field(:postal_code, :string)
    field(:remaining_places, :integer)
    field(:target, :string)
  end
end
