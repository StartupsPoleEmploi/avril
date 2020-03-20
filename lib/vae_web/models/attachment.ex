defmodule Vae.Attachment do
  use VaeWeb, :model

  embedded_schema do
    field :type, :string
    field :target, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :target])
    |> validate_required([:type, :target])
  end

end
