defmodule Vae.Booklet.Cerfa do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Civility, Education, Experience}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:is_complete, :boolean)
    field(:certification_name, :string)
    field(:certifier_name, :string)
    embeds_one(:civility, Civility, on_replace: :delete)
    embeds_one(:education, Education, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:is_complete, :certification_name, :certifier_name])
    |> cast_embed(:civility)
    |> cast_embed(:education)
    |> cast_embed(:experiences)
  end

  def new_cerfa(params \\ %{})

  def new_cerfa(%{}) do
    %__MODULE__{}
  end

  def new_cerfa(params) do
    %__MODULE__{}
    |> cast(params, [:is_complete, :certification_name, :certifier_name])
    |> cast_embed(:education)
    |> cast_embed(:experiences)
  end
end
