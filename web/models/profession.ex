defmodule Vae.Profession do
  use Vae.Web, :model

  schema "professions" do
    field(:slug, :string)
    field(:label, :string)
    field(:priority, :integer)
    belongs_to(:rome, Vae.Rome)
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:label, :priority, :rome_id])
    |> slugify()
    |> validate_required([:label, :slug, :priority])
    |> unique_constraint(:label)
    |> unique_constraint(:slug)
  end

  def format_for_index(struct) do
    struct
    |> Map.take(__schema__(:fields))
    |> Map.put_new(:rome_code, get_in(Map.from_struct(struct.rome), [:code]))
    |> Map.put_new(:length, String.length(struct.label))
    |> Map.put_new(:priority, struct.priority)
    |> Map.drop([:inserted_at, :updated_at])
  end

  def to_slug(profession) do
    Vae.String.parameterize(profession.label)
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end
end
