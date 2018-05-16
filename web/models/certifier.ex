defmodule Vae.Certifier do
  use Vae.Web, :model

  alias Vae.{Certification, Delegate}

  schema "certifiers" do
    field :name, :string

    has_many :certifications, Certification

    has_many :delegates, Delegate

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
