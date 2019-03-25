defmodule Vae.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  alias Vae.{Skill, Experience}

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
    belongs_to(:job_seeker, Vae.JobSeeker)

    # TODO: plug this
    embeds_many(:skills, Skill, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)

    coherence_schema()

    timestamps()
  end

  @fields ~w(name email postal_code address1 address2 address3 address4 insee_code country_code city_label country_code pe_id pe_connect_token)a
  @embeds ~w(skills experiences)a
  @assocs ~w(job_seeker)a

  def changeset(model, params \\ %{}) do
    IO.inspect(params)
    model
    |> cast(params, @fields ++ coherence_fields())
    # |> cast_embed(Map.take(params, @embeds), @embeds)
    # |> cast_assoc(params, @assocs)
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

  # def update_skills_changeset(user, skill_params_array) do
  #   user
  #   |> change()
  #   |> put_embed(:skills, Enum.map(skill_params_array, skill_params -> Skill.changeset(%Skill{}, skill_params) end))
  # end
end
