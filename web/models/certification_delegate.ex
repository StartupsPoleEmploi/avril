defmodule Vae.CertificationDelegate do
  use Vae.Web, :model
  alias Vae.Repo

  schema "certifications_delegates" do
    belongs_to(:certification, Vae.Certification)
    belongs_to(:delegate, Vae.Delegate)
    field(:booklet_1, :string)
    field(:booklet_2, :string)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> Repo.preload(:certification)
    |> Repo.preload(:delegate)
    |> cast(params, [:booklet_1, :booklet_2])
    |> cast_assoc(:certification)
    |> cast_assoc(:delegate)
  end
end
