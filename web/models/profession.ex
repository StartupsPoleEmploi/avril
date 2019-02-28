defmodule Vae.Profession do
  use Vae.Web, :model

  schema "professions" do
    field(:label, :string)
    belongs_to(:rome, Vae.Rome)
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:label])
    |> cast_assoc(:rome, required: true)
    |> validate_required([:label])
    |> unique_constraint(:label)
    |> assoc_constraint(:rome)
  end

  def format_for_index(struct) do
    struct
    |> Map.take(__schema__(:fields))
    |> Map.put_new(:rome_code, struct.rome.code)
    |> Map.drop([:inserted_at, :updated_at])
  end
end
