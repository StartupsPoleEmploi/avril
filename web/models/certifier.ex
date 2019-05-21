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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> slugify
  end

  def to_slug(certifier) do
    Vae.String.parameterize(certifier.name)
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(changeset.data))
  end

  defimpl Phoenix.Param, for: Vae.Certifier do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
