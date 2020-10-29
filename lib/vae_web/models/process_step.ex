# Deprecated : not used anymore
# TODO: remove this

defmodule Vae.ProcessStep do
  use VaeWeb, :model

  schema "processes_steps" do
    field :index, :integer

    belongs_to :process, Vae.Process
    belongs_to :step, Vae.Step
  end

  def add_steps(struct, params \\ %{}) do
    struct
    |> cast(params, [:index])
    |> cast_assoc(:step)
  end
end
