defmodule Vae.Booklet.Education do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Course, Diploma}

  @primary_key false
  embedded_schema do
    field(:grade, :string)
    field(:degree, :string)

    embeds_many :diplomas, Diploma, primary_key: false, on_replace: :delete do
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end

    embeds_many :courses, Course, primary_key: false, on_replace: :delete do
      field(:label, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:label])
      end
    end
  end

  @fields ~w(grade degree)

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:diplomas)
    |> cast_embed(:courses)
  end
end
