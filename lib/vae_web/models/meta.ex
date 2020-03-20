defmodule Vae.Meta do
  use VaeWeb, :model

  embedded_schema do
    field(:title, :string)
    field(:description, :string)
    embeds_one(:attachment, Vae.Attachment)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title])
    |> cast_embed(:attachement)
    |> validate_required([:title])
  end
end
