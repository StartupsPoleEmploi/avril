defmodule Vae.Profession do
  use Vae.Web, :model

  alias __MODULE__

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

  def get_certifications(%Profession{} = profession) do
    profession |> Repo.preload(rome: :certifications) |> Map.get(:rome) |> Map.get(:certifications)
  end

  def to_slug(%Profession{label: label} = _profession) do
    Vae.String.parameterize(label)
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  defimpl Phoenix.Param, for: Vae.Profession do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
