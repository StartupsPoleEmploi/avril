defmodule Vae.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  alias Vae.{Skill, Experience, ProvenExperience, JobSeeker, Application, Repo}

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :is_admin, :boolean
    field :postal_code, :string
    field :address1, :string
    field :address2, :string
    field :address3, :string
    field :address4, :string
    field :insee_code, :string
    field :country_code, :string
    field :city_label, :string
    field :country_label, :string
    field :pe_id, :string
    field :pe_connect_token, :string
    belongs_to(:job_seeker, JobSeeker, on_replace: :update)

    has_many(:applications, Application, on_replace: :delete)

    has_one(
      :delegate,
      through: [:applications, :delegate]
    )

    has_one(
      :certification,
      through: [:applications, :certification]
    )

    embeds_many(:skills, Skill, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
    embeds_many(:proven_experiences, ProvenExperience, on_replace: :delete)

    coherence_schema()

    timestamps()
  end

  @fields ~w(first_name last_name email postal_code address1 address2 address3 address4 insee_code country_code city_label country_label pe_id pe_connect_token)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields ++ coherence_fields())
    |> cast_embed(:skills)
    |> cast_embed(:experiences)
    |> cast_embed(:proven_experiences)
    # |> cast_assoc(:delegate)
    # |> cast_assoc(:certification)
    # |> cast_assoc(:applications, with: Application.changeset_from_users)
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
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end

  def userinfo_api_map(api_fields) do
    %{
      first_name: String.capitalize(api_fields["given_name"]),
      last_name: String.capitalize(api_fields["family_name"]),
      email: String.downcase(api_fields["email"]),
      password: api_fields["password"],
      password_confirmation: api_fields["password_confirmation"],
      pe_id: api_fields["idIdentiteExterne"],
      delegate_id: api_fields["delegate_id"],
      certification_id: api_fields["certification_id"],
      job_seeker: Repo.get_by(JobSeeker, email: String.downcase(api_fields["email"]))
    } |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new
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
end
