defmodule Vae.User do
  require Logger

  @moduledoc false
  use VaeWeb, :model

  use Pow.Ecto.Schema,
    password_hash_methods: {&Bcrypt.hash_pwd_salt/1, &Bcrypt.verify_pass/2}

  use Pow.Extension.Ecto.Schema,
    extensions: [
      # PowEmailConfirmation,
      PowResetPassword
    ]

  import Pow.Ecto.Schema.Changeset,
    only: [new_password_changeset: 3, confirm_password_changeset: 3]

  alias __MODULE__
  alias Vae.Identity

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
    field(:email_confirmed_at, :utc_datetime)
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

    embeds_one(:identity, Identity, on_replace: :update)

    timestamps()
  end

  @fields ~w(
    gender
    first_name
    last_name
    email
    email_confirmed_at
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
  )a

  def changeset(model, params \\ %{})

  def changeset(model, %{"password" => _pw} = params) do
    model
    |> pow_user_id_field_changeset(params)
    |> pow_current_password_changeset(params)
    |> new_password_changeset(params, @pow_config)
    |> maybe_confirm_password(params)
    |> changeset(Map.drop(params, @password_fields))
  end

  # @TODO Remove in favor of create_changeset
  def changeset(model, params) do
    # @TODO Can do better ....
    params = Map.put(params, "identity", params)

    model
    |> cast(params, @fields)
    |> pow_extension_changeset(params)
    |> sync_name_with_first_and_last(params)
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
    |> cast_embed(:identity)
    |> put_job_seeker(params[:job_seeker])
  end

  @doc "Changeset for update a user from admin"
  @deprecated "Until we can find a better way"
  def admin_changeset(model, params) do
    # params = Map.put(params, :identity, params)

    model
    |> cast(params, @fields)
    |> pow_extension_changeset(params)
    |> sync_name_with_first_and_last(params)
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
    |> cast_embed(:identity)
    |> put_job_seeker(params[:job_seeker])
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
    params = map_params_from_pe(user_info)

    %__MODULE__{}
    |> create_changeset(params)
  end

  def update_user_from_pe_changeset(user, params) do
    user
    |> cast(params, @fields)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
  end

  def update_user_email_changeset(changeset, email) do
    changeset
    |> change(%{email: email})
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def map_params_from_pe(user_info) do
    user_info
    |> extra_fields_for_create()
    |> case do
      {:ok, extra_fields} ->
        Map.merge(extra_fields, %{
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

      {:incomplete, default} ->
        default

      {:error, default} ->
        default
    end
  end

  def extra_fields_for_create(%{"idIdentiteExterne" => pe_id, "email" => email}) do
    tmp_password = "AVRIL_#{pe_id}_TMP_PASSWORD"

    {:ok,
     %{
       email: String.downcase(email),
       current_password: nil,
       password: tmp_password,
       password_confirmatin: tmp_password
     }}
  end

  def extra_fields_for_create(%{"idIdentiteExterne" => pe_id}) do
    Logger.error(fn -> "Missing email for #{pe_id}" end)
    {:incomplete, %{}}
  end

  def extra_fields_for_create(_), do: {:error, %{}}

  def update_identity_changeset(model, params) do
    model
    |> cast(params, [])
    |> cast_embed(:identity)
  end

  def register_identity_fields_required_changeset(model, _params \\ %{}) do
    model
    |> cast(%{identity: %{}}, [])
    |> cast_embed(:identity, with: &Identity.validate_required_fields/2)
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

  def address(user) do
    [
      Vae.Account.address_street(user),
      Vae.Account.address_city(user)
    ]
    |> Vae.Enum.join_keep_nil("\n")
  end

  def worked_hours(%User{} = user) do
    user.proven_experiences
    |> Enum.reduce(0, fn pe, acc -> acc + Vae.Maybe.to_integer(pe.work_duration) end)
  end

  def worked_days(%User{} = user) do
    user.proven_experiences
    |> Enum.reduce(0, fn pe, acc -> acc + Vae.Maybe.to_integer(pe.duration) end)
  end

  def is_eligible(%User{} = user) do
    worked_hours(user) >= 1607 || worked_days(user) >= 500
  end

  def submit_application_required_missing_fields(user) do
    Enum.filter(@application_submit_fields, fn field -> is_nil(Map.get(user, field)) end)
  end

  def update_password_changeset(user, attrs) do
    user
    |> pow_password_changeset(attrs)
    |> pow_current_password_changeset(attrs)
  end

  def profile_url(endpoint, path \\ nil)

  def profile_url(endpoint, %UserApplication{} = application) do
    application = Repo.preload(application, :certification)
    profile_url(endpoint, "/mes-candidatures/#{application.id}-#{application.certification.slug}")
  end

  def profile_url(endpoint, path) do
    if is_nil(System.get_env("NUXT_PROFILE_PATH")) do
      Logger.warn("NUXT_PROFILE_PATH environment variable not set")
    end

    %URI{
      path: "#{System.get_env("NUXT_PROFILE_PATH")}#{path || "/"}"
    }
    |> Vae.URI.to_absolute_string(endpoint)
  end
end
