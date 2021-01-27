defmodule Vae.Identity do
  use Ecto.Schema
  use StructAccess
  import Ecto.Changeset

  alias __MODULE__
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
    embeds_one(:full_address, Address, on_replace: :update)
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

  @required_fields_for_submission ~w(
    gender
    first_name
    last_name
    email
    birthday
  )a
  def validate_required_fields(struct, _params \\ %{}) do
    struct
    |> cast(%{full_address: %{}}, [])
    |> validate_required(@required_fields_for_submission)
    |> cast_embed(:full_address, with: &Address.validate_required_fields/2)
  end

  def from_pe_connect_infos(pe_connect_infos) do
    %{
      gender: pe_connect_infos[:gender],
      birthday: pe_connect_infos[:birthday],
      first_name: pe_connect_infos[:first_name],
      last_name: pe_connect_infos[:last_name],
      email: pe_connect_infos[:email],
      full_address: %{
        city: pe_connect_infos[:city_label],
        county: nil,
        country: pe_connect_infos[:country_label],
        lat: nil,
        lng: nil,
        street: [:address1, :address2, :address3, :address4]
          |> Enum.map(&(pe_connect_infos[&1]))
          |> Enum.reject(&Vae.String.is_blank?(&1))
          |> Enum.join(", "),
        postal_code: pe_connect_infos[:postal_code]
      }
    }
  end

  def is_man?(%Identity{gender: gender}) when is_binary(gender) do
    String.starts_with?(gender, "m")
  end

  def is_man?(_), do: true
end
