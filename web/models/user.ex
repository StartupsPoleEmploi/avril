defmodule Vae.User do
  require Logger

  @moduledoc false
  use Vae.Web, :model
  use Pow.Ecto.Schema,
    password_hash_methods: {&Bcrypt.hash_pwd_salt/1,
                            &Bcrypt.functionverify_pass/2}
  # use Pow.Ecto.Schema,
  #   password_hash_methods: {&Comeonin.Bcrypt.hashpwsalt/1,
  #                           &Comeonin.Bcrypt.checkpw/2}
  use Pow.Extension.Ecto.Schema,
    extensions: [PowEmailConfirmation, PowResetPassword]

  alias Vae.{
    Application,
    Experience,
    JobSeeker,
    ProvenExperience,
    Repo,
    Skill
  }

  schema "users" do
    pow_user_fields()

    # Legacy fields to keep data
    field :confirmation_token, :string
    field :confirmed_at, :utc_datetime

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

    has_many(:applications, Application, on_replace: :delete, on_delete: :delete_all)
    # Deprecated
    has_one(:current_application, Application, on_replace: :delete, on_delete: :delete_all)

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
    is_admin
  )a

  @application_submit_fields ~w(
    first_name
    last_name
    email
    postal_code
    city_label
    country_label
    birthday
    confirmed_at
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> pow_changeset(params)
    |> pow_extension_changeset(params)
    |> sync_name_with_first_and_last(params)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
    |> put_embed_if_necessary(params, :booklet_data, is_single: true)
    |> put_job_seeker(params[:job_seeker])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

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

  def fill_with_api_fields({:ok, user} = initial_status, client_with_token) do
    [
      Vae.Profile.ProvenExperiences,
      Vae.Profile.Experiences,
      Vae.Profile.ContactInfo,
      Vae.Profile.Civility,
      Vae.Profile.Skills
    ]
    |> Enum.map(fn mod ->
      Task.async(fn ->
        if(mod.is_data_missing(user)) do
          mod.execute(client_with_token)
        else
          %{}
        end
      end)
    end)
    |> Enum.map(&Task.await(&1, 15_000))
    |> Enum.reduce(initial_status, fn
      map, user when map == %{} ->
        user

      data, {:ok, user} ->
        __MODULE__.changeset(user, data)
        |> Repo.update()

      _data, {:error, changeset} ->
        Logger.error(fn -> inspect(changeset) end)
        {:ok, Repo.get(__MODULE__, user.id)}
    end)
  end

  def fill_with_api_fields({:error, _msg} = error, _client_with_token), do: error

  def userinfo_api_map(api_fields, include_create_fields \\ true) do
    tmp_password = "AVRIL_#{api_fields["idIdentiteExterne"]}_TMP_PASSWORD"

    extra_fields =
      if include_create_fields,
        do: %{
          email: String.downcase(api_fields["email"]),
          password: tmp_password,
          password_confirmation: tmp_password
        },
        else: %{}

    Map.merge(extra_fields, %{
      gender: api_fields["gender"],
      first_name: Vae.String.capitalize(api_fields["given_name"]),
      last_name: Vae.String.capitalize(api_fields["family_name"]),
      pe_id: api_fields["idIdentiteExterne"],
      job_seeker: Repo.get_by(JobSeeker, email: String.downcase(api_fields["email"])),
      confirmed_at: Timex.now()
    })
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  def coordonnees_api_map(api_fields) do
    %{
      postal_code: api_fields["codePostal"],
      address1: Vae.String.titleize(api_fields["adresse1"]),
      address2: Vae.String.titleize(api_fields["adresse2"]),
      address3: Vae.String.titleize(api_fields["adresse3"]),
      address4: Vae.String.titleize(api_fields["adresse4"]),
      insee_code: api_fields["codeINSEE"],
      country_code: api_fields["codePays"],
      city_label: Vae.String.titleize(api_fields["libelleCommune"]),
      country_label: Vae.String.titleize(api_fields["libellePays"])
    }
  end

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

  def formatted_email(user) do
    cond do
      fullname(user) == user.email -> user.email
      true -> {fullname(user), user.email}
    end
  end

  def address_street(user) do
    [user.address1, user.address2, user.address3, user.address4]
    |> Vae.Enum.join_keep_nil(", ")
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
      address_street(user),
      address_city(user)
    ]
    |> Vae.Enum.join_keep_nil("\n")
  end

  def address_inline(user) do
    [
      address_street(user),
      address_city(user)
    ]
    |> Enum.join(", ")
  end

  def submit_application_required_missing_fields(user) do
    Enum.filter(@application_submit_fields, fn field -> is_nil(Map.get(user, field)) end)
  end
end
