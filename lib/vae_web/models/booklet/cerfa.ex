defmodule Vae.Booklet.Cerfa do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Education, Experience}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:condamnation_free, :boolean)
    field(:only_certification_application, :boolean)
    field(:less_than_3_applications, :boolean)
    field(:inserted_at, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:completed_at, :utc_datetime)
    embeds_one(:education, Education, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
    # timestamps() # Unfortunately doesn't work: inserted_at always updated
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:completed_at])
    |> cast(%{
      inserted_at: struct.inserted_at || Timex.now(),
      updated_at: Timex.now(),
      completed_at: (if params.completed_at, do: Timex.now()),
      condamnation_free: !!params.completed_at,
      only_certification_application: !!params.completed_at,
      less_than_3_applications: !!params.completed_at
    }, [
      :inserted_at,
      :updated_at,
      :completed_at,
      :condamnation_free,
      :only_certification_application,
      :less_than_3_applications
    ])
    |> cast_embed(:education)
    |> cast_embed(:experiences)
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      cond do
        data.inserted_at && data.completed_at ->
          "Completed #{
            Timex.Format.DateTime.Formatters.Relative.format!(data.completed_at, "{relative}")
          } in #{
            Timex.diff(data.completed_at, data.inserted_at, :duration)
            |> Timex.Format.Duration.Formatter.format(:humanized)
          }"

        data.inserted_at ->
          "Started #{
            Timex.Format.DateTime.Formatters.Relative.format!(data.inserted_at, "{relative}")
          }"

        data.completed_at ->
          "Completed #{
            Timex.Format.DateTime.Formatters.Relative.format!(data.completed_at, "{relative}")
          }"

        true ->
          "Started"
      end
    end
  end
end
