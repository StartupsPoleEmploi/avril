defmodule Vae.MeetingPlace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:name, :string)
    embeds_many(:meetings, Vae.Meeting, on_replace: :delete)
  end
end
