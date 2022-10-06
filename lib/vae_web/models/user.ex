defmodule Vae.User do
  require Logger

  @moduledoc false
  use VaeWeb, :model

  use Pow.Ecto.Schema,
    password_hash_methods: {&Bcrypt.hash_pwd_salt/1, &Bcrypt.verify_pass/2}

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword]

  import Ecto.Query

  import Pow.Ecto.Schema.Changeset,
    only: [password_changeset: 3]

  alias __MODULE__

  alias Vae.{
    Booklet.Address,
    Delegate,
    Experience,
    Identity,
    ProvenExperience,
    Repo,
    Skill,
    UserApplication
  }

  schema "users" do
    pow_user_fields()

    field(:name, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:is_admin, :boolean)
    field(:is_delegate, :boolean)
    field(:pe_id, :string)
    field(:reset_password_sent_at, :utc_datetime)

    has_many(:applications, UserApplication, on_replace: :delete, on_delete: :delete_all)

    embeds_many(:skills, Skill, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
    embeds_many(:proven_experiences, ProvenExperience, on_replace: :delete)
    embeds_one(:identity, Identity, on_replace: :update)

    timestamps()
  end

  @fields ~w(
    email
    name
    first_name
    last_name
    pe_id
    is_admin
    is_delegate
  )a

  def changeset(model, params \\ %{})

  def changeset(model, params) do
    params = Vae.Map.ensure_atom_keys(params)

    synchronized_email = (
      get_in(params, [:email]) ||
      get_in(params, [:identity, :email]) ||
      model.email ||
      get_in(model.identity || %{}, [:email])
    ) |> case do
      string when is_binary(string) -> string |> String.downcase() |> String.trim()
      _ -> nil
    end

    model
    |> cast(Map.merge(params, %{email: synchronized_email}), @fields)
    |> do_password_changeset(params)
    |> pow_extension_changeset(params)
    |> put_embed_if_necessary(Map.merge(params, %{identity: Map.merge(get_in(params, [:identity]) || %{}, %{email: synchronized_email})}), :identity)
    |> put_embed_if_necessary(params, :skills)
    |> put_embed_if_necessary(params, :experiences)
    |> put_embed_if_necessary(params, :proven_experiences)
    |> extract_identity_data()
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_password_rules()
  end

  def do_password_changeset(changeset, %{
    password: password
  } = params) do
    case changeset.data.password_hash do
      existing_password when is_binary(existing_password) -> pow_current_password_changeset(changeset, params)
      _ -> changeset
    end
    |> password_changeset(Map.merge(params, %{
      password_confirmation: password
    }), @pow_config)
  end

  def do_password_changeset(changeset, _), do: changeset


  defp validate_password_rules(changeset) do
    password_rules = [
      # {"doit avoir une longueur de minimum #{Application.get_env(:vae, :pow)[:password_min_length]} caractères", &(String.length(&1) >= Application.get_env(:vae, :pow)[:password_min_length])},
      {"doit contenir au moins une lettre, un nombre et un caractère spécial parmis & - _ @ * + = . , ; : ! ?", &Vae.String.has_all_kind_of_chars?(&1)},
    ]

    Ecto.Changeset.validate_change(changeset, :password, fn :password, password ->
      Enum.reduce(password_rules, nil, fn {msg, test_fn}, error_msg ->
        error_msg || !test_fn.(password) && msg
      end)
      |> case do
        error_msg when is_binary(error_msg) -> [password: error_msg]
        _ -> []
      end
    end)
  end

  def reset_random_password(user) do
    password = "#{Vae.String.generate_hash(8)}@#{Vae.String.generate_hash(8)}1"
    password_changeset(user, %{
      password: password,
      password_confirmation: password,
    }, @pow_config)
    |> Repo.update()
  end

  def extract_identity_data(changeset) do
    duplicated_fields = ~w(email first_name last_name)a

    Enum.reduce(duplicated_fields, changeset, fn field, changeset ->
      value = (get_field(changeset, :identity) || %{})
        |> Map.get(field)

      put_change(changeset, field, value || get_field(changeset, field))
    end)
  end

  def downcase_email(changeset) do
    case get_field(changeset, :email) do
      email when is_binary(email) -> put_change(changeset, :email, String.downcase(email))
      nil -> changeset
    end
  end

  def can_submit_or_register?(%User{} = user) do
    %Ecto.Changeset{valid?: valid} = changeset = user
    |> cast(%{identity: %{}}, [])
    |> cast_embed(:identity, with: &Identity.validate_required_fields/2)

    if valid, do: {:ok, changeset}, else: {:error, changeset}
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

  def fullname(%User{
    first_name: first_name,
    last_name: last_name,
    email: email,
    identity: identity
  }), do:
    Vae.String.blank_is_nil("#{identity[:first_name] || first_name} #{identity[:last_name] || last_name}") || email

  def formatted_email(%User{email: email} = user) do
    case fullname(user) do
      name when name == email -> email
      name -> {name, email}
    end
  end

  def address(%{identity: %Identity{full_address: address}}), do: Address.address(address)
  def address(_), do: nil

  def delegatable?(%User{email: email}) do
    Repo.exists?(
      from d in Delegate,
      where: d.email == ^email or d.secondary_email == ^email
    )
  end

  def delegatable?(_), do: false

  def delegates(%User{is_delegate: true, email: email}) do
    Repo.all(
      from d in Delegate,
      where: d.email == ^email or d.secondary_email == ^email,
      order_by: {:asc, d.name}
    )
  end

  def delegates(_), do: []

  def delegate_ids(user), do: Enum.map(User.delegates(user), &(&1.id))

  def transferable_applications(%User{id: user_id}) do
    from(
      a in UserApplication.transferable_applications_query(),
      where: a.user_id == ^user_id
    ) |> Repo.all()
  end

  def transferable_applications(_), do: []

  def reset_old_users_password() do
    # from(u in User, where: fragment("?::date", u.inserted_at) < ^~D[2022-09-29])
    # |> Repo.update_all(set: [reset_password_sent_at: DateTime.utc_now()])

    six_months_ago = Date.utc_today() |> Timex.shift(months: -6)
    from(u in User, where:
      fragment("?::date", u.inserted_at) < ^six_months_ago and
      not is_nil(u.reset_password_sent_at) and not is_nil(u.password_hash)
    )
    |> Repo.all()
    |> Enum.each(&User.reset_random_password(&1))
  end

end
