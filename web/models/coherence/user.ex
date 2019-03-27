defmodule Vae.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  alias Vae.{Skill, Experience, JobSeeker, Repo}

  schema "users" do
    field :name, :string
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
    belongs_to(:job_seeker, JobSeeker)

    embeds_many(:skills, Skill, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)

    coherence_schema()

    timestamps()
  end

  @fields ~w(name email postal_code address1 address2 address3 address4 insee_code country_code city_label country_label pe_id pe_connect_token)a
  @embeds ~w(skills experiences)a
  @assocs ~w(job_seeker)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields ++ coherence_fields())
    |> cast_embed(:skills)
    |> cast_embed(:experiences)
    # |> put_assoc(:job_seeker)
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end

  def userinfo_api_map(api_fields) do
    %{
      name: "#{String.capitalize(api_fields["given_name"])} #{String.capitalize(api_fields["family_name"])}",
      email: String.downcase(api_fields["email"]),
      password: api_fields["password"],
      password_confirmation: api_fields["password_confirmation"],
      pe_id: api_fields["idIdentiteExterne"],
      job_seeker: Repo.get_by(JobSeeker, email: String.downcase(api_fields["email"]))
    }
  end

  def coordonnees_api_map(api_fields) do
    IO.inspect(api_fields)
    %{
      postal_code: api_fields["codePostal"],
      address1: api_fields["adresse1"],
      address2: api_fields["adresse2"],
      address3: api_fields["adresse3"],
      address4: api_fields["adresse4"],
      insee_code: api_fields["codeINSEE"],
      country_code: api_fields["codePays"],
      city_label: api_fields["libelleCommune"],
      country_label: api_fields["libellePays"]
    }
  end
end
