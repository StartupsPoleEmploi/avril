defmodule Vae.Rome do
  use Vae.Web, :model
  alias Vae.{Certification, Profession, Repo}

  alias __MODULE__

  schema "romes" do
    field(:slug, :string)
    field(:code, :string) # TODO: make sure this column is indexed so that category navigation is fast
    field(:label, :string)
    field(:url, :string)

    has_many(:professions, Profession)

    many_to_many(:certifications, Certification,
      join_through: "rome_certifications",
      on_delete: :delete_all
    )

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :label, :url])
    |> slugify
    |> validate_required([:code, :label, :slug])
  end

  # def all() do
  #   Rome
  #   |> order_by(:code)
  #   |> Repo.all()
  # end

  def format_for_index(struct) do
    struct
    |> Map.take(__schema__(:fields))
    |> Map.drop([:inserted_at, :updated_at])
  end

  def get(nil), do: nil
  def get(id), do: Repo.get(Rome, id)

  def get_by_code(nil), do: nil
  def get_by_code(code), do: Repo.get_by(Rome, code: code)

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

  def category(rome) do
    %{category: category} = __MODULE__.code_parts(rome)
    if category != rome.code do
      Repo.get_by(__MODULE__, code: category)
    end
  end

  def subcategory(rome) do
    %{subcategory: subcategory} = __MODULE__.code_parts(rome)
    if subcategory != rome.code do
      Repo.get_by(__MODULE__, code: subcategory)
    end
  end

  def subcategories(rome) do
    %{category: category} = __MODULE__.code_parts(rome)
    query = from m in __MODULE__, where: like(m.code, ^("#{category}__"))
    Repo.all(query)
  end

  def romes(rome) do
    %{subcategory: subcategory} = __MODULE__.code_parts(rome)
    query = from m in __MODULE__, where: like(m.code, ^("#{String.pad_trailing(subcategory, 5, "_")}"))
    Repo.all(query)
  end

  def to_slug(rome) do
    Vae.String.parameterize(rome.label)
  end

  def slugify(changeset) do
    put_change(changeset, :slug, to_slug(Map.merge(changeset.data, changeset.changes)))
  end

  defimpl Phoenix.Param, for: Vae.Rome do
    def to_param(%{id: id, slug: slug}) do
      "#{id}-#{slug}"
    end
  end
end
