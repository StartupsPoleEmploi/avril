defmodule Vae.Rome do
  use VaeWeb, :model
  alias Vae.{Certification, Profession, Repo}

  alias __MODULE__

  schema "romes" do
    field(:slug, :string)
    field(:code, :string)
    field(:label, :string)
    field(:views, :integer)
    field(:url, :string)

    has_many(:professions, Profession)

    many_to_many(:certifications,
      Certification,
      join_through: "rome_certifications",
      on_delete: :delete_all
    )

    many_to_many(
      :active_certifications,
      Certification,
      join_through: "rome_certifications",
      where: [is_active: true]
    )

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :label, :url, :views])
    |> slugify()
    |> validate_required([:code, :label, :slug, :views])
    |> unique_constraint(:slug)
  end

  def code_parts(rome) do
    %{
      category: String.slice(rome.code, 0..0),
      subcategory: String.slice(rome.code, 0..2),
      code: String.slice(rome.code, 0..5),
    }
  end

  def is_category?(rome) do
    Regex.match?(~r/^[A-Z]$/, rome.code)
  end

  def is_subcategory?(rome) do
    Regex.match?(~r/^[A-Z]\d\d$/, rome.code)
  end

  def is_rome?(rome) do
    Regex.match?(~r/^[A-Z]\d{4}$/, rome.code)
  end

  def categories() do
    query = from m in Rome, where: like(m.code, ^("_"))
    Repo.all(query)
  end

  def category(rome) do
    %{category: category} = code_parts(rome)
    if category != rome.code do
      Repo.get_by(Rome, code: category)
    end
  end

  def subcategory(rome) do
    %{subcategory: subcategory} = code_parts(rome)
    if subcategory != rome.code do
      Repo.get_by(Rome, code: subcategory)
    end
  end

  def subcategories() do
    query = from m in Rome, where: like(m.code, ^("___")), order_by: [asc: :code]
    Repo.all(query)
  end

  def subcategories(rome) do
    %{category: category} = code_parts(rome)
    query = from m in Rome, where: like(m.code, ^("#{category}__")), order_by: [asc: :code]
    Repo.all(query)
  end

  def romes(rome, options \\ []) do
    %{subcategory: subcategory} = code_parts(rome)
    query = from m in Rome, [
      where: like(m.code, ^("#{String.pad_trailing(subcategory, 5, "_")}")),
      order_by: [asc: :code],
      preload: ^(options[:preload] || [])
    ]
    Repo.all(query)

  end

  def name(%Rome{label: label}) do
    label
  end

  def code_name(%Rome{code: code} = rome) do
    "#{code} - #{name(rome)}"
  end

  def to_slug(%Rome{} = rome) do
    rome
    |> name()
    |> Vae.String.parameterize()
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  # TODO: move to analytics?
  def increase_views(%Rome{} = rome) do
    rome
    |> Rome.changeset(%{views: rome.views + 1})
    |> Repo.update()
  end

  defimpl Phoenix.Param, for: Vae.Rome do
    def to_param(%{code: code, slug: slug}) do
      "#{code}-#{slug}"
    end
  end
end
