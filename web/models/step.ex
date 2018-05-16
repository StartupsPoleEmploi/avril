defmodule Vae.Step do
  use Vae.Web, :model

  alias __MODULE__

  alias Vae.ProcessStep

  schema "steps" do
    field :title, :string
    field :content, :string

    has_many :processes_steps, ProcessStep, on_delete: :delete_all
    has_many :processes, through: [:processes_steps, :process]
  end

  def from_delegate(delegate) do
    from s in Step,
      join: ps in assoc(s, :processes_steps),
      where: ps.process_id == ^delegate.process_id,
      order_by: ps.index
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :content])
    |> validate_required([:title, :content])
  end

  def create_changeset(step, params \\ %{}) do
    step
    |> cast(params, ~w(title content))
    |> validate_required([:title, :content])
  end
end
