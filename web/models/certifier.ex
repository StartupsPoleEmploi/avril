
defmodule Vae.Certifier do
  use Vae.Web, :model

  alias Vae.{Certification, Delegate}

  schema "certifiers" do
    field(:slug, :string)
    field(:name, :string)

    many_to_many(
      :certifications,
      Certification,
      join_through: "certifier_certifications",
      on_delete: :delete_all,
      on_replace: :delete
    )

    many_to_many(
      :delegates,
      Delegate,
      join_through: "certifiers_delegates",
      on_delete: :delete_all
    )

    timestamps()
  end

  @educ_nat_id 2

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> slugify
    |> validate_required([:name, :slug])
  end

  def to_slug(certifier) do
    Vae.String.parameterize(certifier.name)
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  def is_educ_nat?(%__MODULE__{} = certifier), do: certifier.id == @educ_nat_id

  defimpl Phoenix.Param, for: Vae.Certifier do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
