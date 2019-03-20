defmodule Vae.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Visit

  @primary_key false
  embedded_schema do
    field(:date, :date)

    embeds_many(:visits, Visit, on_replace: :delete)
  end

  @fields ~w(date)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:visits)
  end

  def create_visits_changeset(analytic, params \\ %{}) do
    analytic
    |> change(params)
    |> cast_embed(:visits)
  end

  def update_visits_changeset(analytic, visit) do
    analytic
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:visits, [visit | analytic.visits])
    |> Ecto.Changeset.apply_changes()
  end

  def new() do
    %__MODULE__{
      date: Date.utc_today()
    }
  end
end
