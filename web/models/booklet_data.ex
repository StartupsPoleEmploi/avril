defmodule Vae.BookletData do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:identity, :map)
    field(:education, :map)
    field(:experiences, {:array, :map})
  end

  @fields ~w(identity education experiences)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end
end
