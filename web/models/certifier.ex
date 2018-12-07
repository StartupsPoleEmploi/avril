defmodule Vae.Certifier do
  use Vae.Web, :model

  alias Vae.{Certification, Delegate}

  schema "certifiers" do
    field(:name, :string)

    has_many(:certifications, Certification)

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
  end
end
