defmodule Vae.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  alias Vae.{Skill, Experience, ProvenExperience, JobSeeker, Application, Repo, OAuth}

  schema "users" do
    field(:gender, :string)
    field(:name, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
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

    coherence_schema()

    timestamps()
  end

  @fields ~w(
    gender
    name
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
    pe_id
    pe_connect_token
    is_admin
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields ++ coherence_fields())
    |> put_embed(
      :skills,
      Enum.uniq_by(
        model.skills ++
          List.wrap(params[:skills]),
        &Skill.unique_key/1
      )
    )
    |> put_embed(
      :experiences,
      Enum.uniq_by(
        model.experiences ++
          List.wrap(params[:experiences]),
        &Experience.unique_key/1
      )
    )
    |> put_embed(
      :proven_experiences,
      Enum.uniq_by(
        model.proven_experiences ++
          List.wrap(params[:proven_experiences]),
        &ProvenExperience.unique_key/1
      )
    )
    |> put_job_seeker(params[:job_seeker])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  defp put_job_seeker(changeset, nil), do: changeset
  defp put_job_seeker(changeset, job_seeker), do: put_assoc(changeset, :job_seeker, job_seeker)

  def changeset(model, params, :password) do
    model
    |> cast(
      params,
      ~w(password password_confirmation reset_password_token reset_password_sent_at)
    )
    |> validate_coherence_password_reset(params)
  end

  def create_or_update_with_pe_connect_data(%{"email" => email} = userinfo_api_result)
      when is_binary(email) do
    case Repo.get_by(__MODULE__, email: String.downcase(email)) do
      nil ->
        Repo.insert(
          __MODULE__.changeset(%__MODULE__{}, __MODULE__.userinfo_api_map(userinfo_api_result))
        )

      user ->
        __MODULE__.update_with_pe_connect_data(user, userinfo_api_result)
    end
  end

  def create_or_update_with_pe_connect_data(_userinfo_api_result),
    do: {:error, "No email in API results"}

  def update_with_pe_connect_data(user, userinfo_api_result) do
    user
    |> Repo.preload(:job_seeker)
    |> __MODULE__.changeset(__MODULE__.userinfo_api_map(userinfo_api_result, false))
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
          res = mod.execute(client_with_token)
        else
          %{}
        end
      end)
    end)
    |> Enum.map(&Task.await(&1, 15_000))
    |> Enum.reduce(initial_status, fn
      %{}, user ->
        user

      data, {:ok, user} ->
        __MODULE__.changeset(user, data)
        |> Repo.update()

      data, {:error, changeset} ->
        Logger.error(fn -> inspect(changeset) end)
        Repo.get(__MODULE__, user.id)
    end)
  end

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
      name:
        "#{String.capitalize(api_fields["given_name"])} #{
          String.capitalize(api_fields["family_name"])
        }",
      gender: api_fields["gender"],
      first_name: String.capitalize(api_fields["given_name"]),
      last_name: String.capitalize(api_fields["family_name"]),
      pe_id: api_fields["idIdentiteExterne"],
      job_seeker: Repo.get_by(JobSeeker, email: String.downcase(api_fields["email"]))
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

  def fullname(user) do
    user.name || "#{user.first_name} #{user.last_name}"
  end

  def address(user) do
    [
      [user.address1, user.address2, user.address3, user.address4],
      ["#{user.postal_code} #{user.city_label}", user.country_label]
    ]
    |> Enum.map(fn list ->
      list
      |> Enum.filter(fn el -> el end)
      |> Enum.join(", ")
    end)
    |> Enum.join("\n")
  end
end
