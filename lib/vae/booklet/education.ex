defmodule Vae.Booklet.Education do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Course, Diploma}

  embedded_schema do
    field(:grade, :string)
    field(:degree, :string)

    embeds_many(:diplomas, Diploma, on_replace: :delete)
    embeds_many(:courses, Course, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:grade, :degree])
    |> cast_embed(:diplomas)
    |> cast_embed(:courses)
  end
end
