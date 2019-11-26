defmodule Vae.Booklet.Cerfa do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Civility, Education, Experience}

  @primary_key false
  embedded_schema do
    field(:certification_name, :string)
    embeds_one(:civility, Civility, on_replace: :delete)
    embeds_one(:education, Education, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:certification_name])
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
    |> cast(params, [:certification_name])
    |> cast_embed(:education)
    |> cast_embed(:experiences)
  end
end
