defmodule Vae.Booklet.Diploma do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:label, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:label])
  end
end
