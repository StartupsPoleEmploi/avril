defmodule Vae.FAQ do
  use VaeWeb, :model

  schema "faqs" do
    field(:question, :string)
    field(:answer, :string)
    field(:order, :integer)
    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(
      params,
      ~w(question answer order)a
    )
    |> validate_required([:question, :answer])
  end

end
