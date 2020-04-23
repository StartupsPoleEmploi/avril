defmodule Vae.User do
  require Logger

  @moduledoc false
  use VaeWeb, :model

  use Pow.Ecto.Schema,
    password_hash_methods: {&Bcrypt.hash_pwd_salt/1, &Bcrypt.verify_pass/2}

  use Pow.Extension.Ecto.Schema,
    extensions: [PowEmailConfirmation, PowResetPassword]

  import Pow.Ecto.Schema.Changeset,
    only: [new_password_changeset: 3, confirm_password_changeset: 3]

  alias Vae.Booklet.Civility

  alias Vae.{
    UserApplication,
    Experience,
    JobSeeker,
    ProvenExperience,
    Repo,
    Skill
  }

  schema "users" do
    pow_user_fields()

    # Legacy fields to keep data
    # field :confirmation_token, :string
    # field :confirmed_at, :utc_datetime

    field(:gender, :string, default: "female")
    field(:name, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    # field(:email, :string)
    field(:phone_number, :string)
    field(:is_admin, :boolean)
    field(:postal_code, :string)
    field(:address1, :string)
    field(:address2, :string)
    field(:address3, :string)
    field(:address4, :string)
    field(:insee_code, :string)
    field(:country_code, :string)
    field(:city_label, :string)
    field(:country_label, :string)
    field(:birthday, :date)
    field(:birth_place, :string)
    field(:pe_id, :string)
    field(:pe_connect_token, :string)

    belongs_to(:job_seeker, JobSeeker, on_replace: :update)

    has_many(:applications, UserApplication, on_replace: :delete, on_delete: :delete_all)
    # Deprecated
    has_one(:current_application, UserApplication, on_replace: :delete, on_delete: :delete_all)

    has_one(
      :current_delegate,
      through: [:current_application, :delegate],
      on_delete: :nilify
    )

    has_one(
      :current_certification,
      through: [:current_application, :certification],
      on_delete: :nilify
    )

    embeds_many(:skills, Skill, on_replace: :delete)

    embeds_many(:experiences, Experience, on_replace: :delete)

    embeds_many(:proven_experiences, ProvenExperience, on_replace: :delete)

    embeds_one(:identity, Civility, on_replace: :update)

    timestamps()
  end

  @fields ~w(
    gender
    first_name
    last_name
    email
    phone_number
    postal_code
    address1
    address2
    address3
    address4
    insee_code
    country_code
    city_label
    country_label
    birthday
    birth_place
    pe_id
    pe_connect_token
    email_confirmed_at
    is_admin
  )a

  @password_fields ~w(
    password
    password_confirmation
    current_password
  )

  @application_submit_fields ~w(
    gender
    first_name
    last_name
    email
    postal_code
    city_label
    country_label
    birthday
    email_confirmed_at
  )a

  def changeset(model, params \\ %{})

  def changeset(model, %{"password" => _pw} = params) do
    model
    |> pow_user_id_field_changeset(params)
    |> pow_current_password_changeset(params)
    |> new_password_changeset(params, @pow_config)
    |> maybe_confirm_password(params)
    |> changeset(Map.drop(params, @password_fields))
    |> put_identity(params)
  end

  # @TODO Remove in favor of create_changeset
  def changeset(model, params) do
    model
    |> cast(params, @fields)
    |> pow_extension_changeset(params)
    |> sync_name_with_first_and_last(params)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
    # |> put_embed_if_necessary(params, :booklet_data, is_single: true)
    |> put_job_seeker(params[:job_seeker])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def create_changeset(model, params) do
    model
    |> cast(params, @fields)
    |> pow_extension_changeset(params)
    |> sync_name_with_first_and_last(params)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
    |> put_job_seeker(params[:job_seeker])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def update_changeset(model, params) do
    model
    |> cast(params, @fields)
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def create_user_from_pe_changeset(user_info) do
    %__MODULE__{}
    |> create_changeset(map_params_from_pe(user_info))
  end

  def map_params_from_pe(user_info) do
    user_info
    |> extra_fields_for_create()
    |> Map.merge(%{
      gender: user_info["gender"],
      first_name: Vae.String.capitalize(user_info["given_name"]),
      last_name: Vae.String.capitalize(user_info["family_name"]),
      pe_id: user_info["idIdentiteExterne"],
      job_seeker:
        Repo.get_by(JobSeeker,
          email: String.downcase(user_info["email"])
        ),
      email_confirmed_at: Timex.now()
    })
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  def extra_fields_for_create(%{"peIdentiteExterne" => pe_id, "email" => email}) do
    tmp_password = "AVRIL_#{pe_id}_TMP_PASSWORD"

    %{
      email: String.downcase(email),
      current_password: nil,
      password: tmp_password,
      password_confirmatin: tmp_password
    }
  end

  def update_identity_changeset(model, params) do
    model
    |> cast(params, [])
    |> cast_embed(:identity)
  end

  def register_fields_required_changeset(model, params \\ %{}) do
    model
    |> cast(params, [])
    |> validate_required(@application_submit_fields)
  end

  defp put_identity(changeset, params) do
    changeset
    |> cast_embed(:identity, %{email: params[:email]})
  end

  defp identity_map(u) do
    %{
      gender: u.gender,
      birthday: u.birthday,
      first_name: u.first_name,
      last_name: u.last_name,
      usage_name: nil,
      email: u.email,
      home_phone: nil,
      mobile_phone: u.phone_number,
      is_handicapped: false,
      birth_place: %{
        city: u.birth_place,
        county: nil
      },
      full_address: %{
        city: u.city_label,
        county: nil,
        country: u.country_label,
        lat: nil,
        lng: nil,
        street: Vae.Account.address_street(u),
        postal_code: u.postal_code
      },
      current_situation: %{},
      nationality: %{
        country: nil,
        country_code: nil
      }
    }
  end

  defp maybe_confirm_password(
         changeset,
         %{"password_confirmation" => _password_confirmation} = attrs
       ),
       do: confirm_password_changeset(changeset, attrs, @pow_config)

  defp maybe_confirm_password(changeset, _attrs), do: changeset

  defp put_job_seeker(changeset, nil), do: changeset
  defp put_job_seeker(changeset, job_seeker), do: put_assoc(changeset, :job_seeker, job_seeker)

  def put_embed_if_necessary(changeset, params, key, _options \\ []) do
    klass_name = key |> Inflex.camelize() |> Inflex.singularize() |> String.to_atom()
    klass = [Elixir, Vae, klass_name] |> Module.concat()

    case params[key] do
      nil ->
        changeset

      values when is_list(values) ->
        put_embed(
          changeset,
          key,
          Enum.uniq_by(
            Map.get(changeset.data, key) ++ values,
            &klass.unique_key/1
          )
        )

      value ->
        put_embed(changeset, key, value)
    end
  end

  def create_or_update_with_pe_connect_data(%{"email" => email} = userinfo_api_result)
      when is_binary(email) do
    case Repo.get_by(__MODULE__, email: String.downcase(email)) do
      nil ->
        Repo.insert(changeset(%__MODULE__{}, userinfo_api_map(userinfo_api_result)))

      user ->
        update_with_pe_connect_data(user, userinfo_api_result)
    end
  end

  def create_or_update_with_pe_connect_data(_userinfo_api_result),
    do: {:error, "No email in API results"}

  def update_with_pe_connect_data(user, userinfo_api_result) do
    user
    |> Repo.preload(:job_seeker)
    |> changeset(userinfo_api_map(userinfo_api_result, false))
    |> Repo.update()
  end

  def fill_with_api_fields({:error, _msg} = error, _client_with_token), do: error

  def sync_name_with_first_and_last(user_changeset, params) do
    first_name = params[:first_name] || user_changeset.data.first_name
    last_name = params[:last_name] || user_changeset.data.last_name

    cast(
      user_changeset,
      %{
        name: "#{first_name} #{last_name}"
      },
      [:name]
    )
  end

  def fullname(user) do
    Vae.String.blank_is_nil(user.name) ||
      Vae.String.blank_is_nil("#{user.first_name} #{user.last_name}") ||
      user.email
  end

  def name(user) do
    fullname(user)
  end

  def formatted_email(user) do
    cond do
      fullname(user) == user.email -> user.email
      true -> {fullname(user), user.email}
    end
  end

  def address_city(user) do
    [
      Vae.Enum.join_keep_nil([user.postal_code, user.city_label], " "),
      user.country_label
    ]
    |> Vae.Enum.join_keep_nil(", ")
  end

  def address(user) do
    [
      Vae.Account.address_street(user),
      address_city(user)
    ]
    |> Vae.Enum.join_keep_nil("\n")
  end

  def address_inline(user) do
    [
      Vae.Account.address_street(user),
      address_city(user)
    ]
    |> Enum.join(", ")
  end

  def submit_application_required_missing_fields(user) do
    Enum.filter(@application_submit_fields, fn field -> is_nil(Map.get(user, field)) end)
  end

  def update_password_changeset(user, attrs) do
    user
    |> pow_password_changeset(attrs)
    |> pow_current_password_changeset(attrs)
  end
end
