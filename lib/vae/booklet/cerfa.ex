defmodule Vae.Booklet.Cerfa do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Civility, Education, Experience}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:completed_at, :utc_datetime)
    field(:certification_name, :string)
    field(:certifier_name, :string)
    embeds_one(:civility, Civility, on_replace: :delete)
    embeds_one(:education, Education, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:completed_at, :certification_name, :certifier_name])
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
    |> cast(params, [:completed_at, :certification_name, :certifier_name])
    |> cast_embed(:education)
    |> cast_embed(:experiences)
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      cond do
        is_nil(data) -> "Non"
        data.completed_at -> "Terminé"
        true -> "Démarré"
      end
    end
  end


end
