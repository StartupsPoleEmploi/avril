defmodule Vae.Profession do
  use Vae.Web, :model

  schema "professions" do
    field :label, :string
    belongs_to :rome, Vae.Rome
    timestamps()
  end

  def search(query, nil) do
    from p in query,
      preload: [:rome]
  end

  def search(query, label) do
    from p in query,
      join: r in assoc(p, :rome),
      where: ilike(p.label, ^"%#{label}%") or
             ilike(r.label, ^"%#{label}%"),
      order_by: [asc: :label],
      preload: [:rome]
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
end
