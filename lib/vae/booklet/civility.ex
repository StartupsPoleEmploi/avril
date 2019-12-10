defmodule Vae.Booklet.Civility do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Booklet.{Address, CurrentSituation}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:gender, :string)
    field(:birthday, :date)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:usage_name, :string)
    field(:email, :string)
    field(:home_phone, :string)
    field(:mobile_phone, :string)
    field(:is_handicapped, :boolean)

    embeds_one(:birth_place, Address, on_replace: :delete)
    embeds_one(:full_address, Address, on_replace: :delete)
    embeds_one(:current_situation, CurrentSituation, on_replace: :delete)

    embeds_one :nationality, Nationality, primary_key: false, on_replace: :delete do
      @derive Jason.Encoder
      field(:country, :string)
      field(:country_code, :string)

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:country, :country_code])
      end
    end
  end

  @fields ~w(
    gender
    birthday
    first_name
    last_name
    usage_name
    email
    home_phone
    mobile_phone
    is_handicapped
  )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> cast_embed(:birth_place)
    |> cast_embed(:full_address)
    |> cast_embed(:current_situation)
    |> cast_embed(:nationality)
  end
end
