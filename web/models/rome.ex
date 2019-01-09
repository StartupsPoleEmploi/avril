defmodule Vae.Rome do
  use Vae.Web, :model
  alias Vae.Repo.NewRelic, as: Repo

  schema "romes" do
    field :code, :string
    field :label, :string
    field :url, :string

    has_many :professions, Vae.Profession
    many_to_many :certifications, Vae.Certification, join_through: "rome_certifications", on_delete: :delete_all

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:code, :label, :url])
    |> validate_required([:code, :label])
  end

  def all do
    __MODULE__
    |> order_by(:code)
    |> Repo.all
  end

  def format_for_index(delegate) do
    delegate
    |> Map.take(__schema__(:fields))
    |> Map.drop([:inserted_at, :updated_at])
  end
end
