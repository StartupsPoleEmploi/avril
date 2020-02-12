defmodule Vae.Booklet.Cerfa do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Civility, Education, Experience}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:inserted_at, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:completed_at, :utc_datetime)
    field(:certification_name, :string)
    field(:certifier_name, :string)
    embeds_one(:civility, Civility, on_replace: :delete)
    embeds_one(:education, Education, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
    # timestamps() # Unfortunately doesn't work: inserted_at always updated
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:completed_at, :certification_name, :certifier_name])
    |> cast(%{inserted_at: struct.inserted_at || Timex.now(), updated_at: Timex.now()}, [:inserted_at, :updated_at])
    |> cast_embed(:civility)
    |> cast_embed(:education)
    |> cast_embed(:experiences)
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      cond do
        data.inserted_at && data.completed_at -> "Completed #{Timex.Format.DateTime.Formatters.Relative.format!(data.completed_at, "{relative}")} in #{Timex.diff(data.completed_at, data.inserted_at, :duration) |> Timex.Format.Duration.Formatter.format(:humanized)}"
        data.inserted_at -> "Started #{Timex.Format.DateTime.Formatters.Relative.format!(data.inserted_at, "{relative}")}"
        data.completed_at -> "Completed #{Timex.Format.DateTime.Formatters.Relative.format!(data.completed_at, "{relative}")}"
        true -> "Started"
      end
    end
  end
end
