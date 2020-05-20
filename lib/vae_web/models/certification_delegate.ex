defmodule Vae.CertificationDelegate do
  use VaeWeb, :model
  alias Vae.{Certification, Delegate, Repo}

  schema "certifications_delegates" do
    belongs_to(:certification, Certification)
    belongs_to(:delegate, Delegate)
    field(:booklet_1, :string)
    field(:booklet_2, :string)
    field(:_destroy, :boolean, virtual: true)
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
    |> mark_for_deletion()
  end


  defp mark_for_deletion(changeset) do
    # If delete was set and it is true, let's change the action
    if get_change(changeset, :_destroy) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
