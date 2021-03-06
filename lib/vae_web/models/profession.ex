defmodule Vae.Profession do
  use VaeWeb, :model

  alias __MODULE__
  alias Vae.Repo

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

  def get_certifications(%Profession{} = profession) do
    profession |> Repo.preload(rome: :certifications) |> Map.get(:rome) |> Map.get(:certifications)
  end

  def name(%Profession{label: label}), do: label

  def to_slug(%Profession{} = p), do: Vae.String.parameterize(name(p))

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  defimpl Phoenix.Param, for: Vae.Profession do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
