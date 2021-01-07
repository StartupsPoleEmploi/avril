defmodule Vae.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Search

  @primary_key false
  embedded_schema do
    field(:path_info, {:array, :string})
    field(:certification_id, :integer)
    field(:delegate_id, :integer)

    embeds_one(:search, Search, on_replace: :delete) do
      @derive Jason.Encoder
      field(:rome_code, :string)
      field(:profession, :string)
      field(:geolocation_text, :string)
      field(:lat, :string)
      field(:lng, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, ~w(rome_code profession geolocation_text lat lng)a)
      end
    end
  end

  @fields ~w(path_info certification_id delegate_id)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end
end
