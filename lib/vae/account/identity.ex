defmodule Vae.Identity do
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

  def from_user(user) do
    %{
      gender: user.gender,
      birthday: user.birthday,
      first_name: user.first_name,
      last_name: user.last_name,
      usage_name: nil,
      email: user.email,
      home_phone: nil,
      mobile_phone: user.phone_number,
      is_handicapped: false,
      birth_place: %{
        city: user.birth_place,
        county: nil
      },
      full_address: %{
        city: user.city_label,
        county: nil,
        country: user.country_label,
        lat: nil,
        lng: nil,
        street: Vae.Account.address_street(user),
        postal_code: user.postal_code
      },
      current_situation: %{},
      nationality: %{
        country: nil,
        country_code: nil
      }
    }
  end

  def fullname(%{first_name: first_name, last_name: last_name, email: email}) do
    Vae.String.blank_is_nil("#{first_name} #{last_name}") || email
  end

  def fullname(%{email: email}), do: email

  def formatted_email(%{identity: %{}} = user), do: user.email

  def formatted_email(%{identity: identity} = user) do
    if fullname(user) == identity.email do
      identity.email
    else
      {fullname(user), identity.email}
    end
  end
end
