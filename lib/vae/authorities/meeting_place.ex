defmodule Vae.MeetingPlace do
  use Ecto.Schema

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:name, :string)
    embeds_many(:meetings, Vae.Meeting, on_replace: :delete)
  end
end
