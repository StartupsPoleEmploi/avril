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

      user -> __MODULE__.update_with_pe_connect_data(user, userinfo_api_result)
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

  def build_api_calls do
    [
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-datenaissance/v1/etat-civil",
        is_data_missing: &is_nil(&1.birthday),
        data_map: fn data -> %{birthday: Timex.parse!(data["dateDeNaissance"], "{ISO:Extended}")} end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees",
        is_data_missing: &is_nil(&1.postal_code),
        data_map: &__MODULE__.coordonnees_api_map/1
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences",
        is_data_missing: &Enum.empty?(&1.skills),
        data_map: fn data -> %{skills: Enum.map(data, &Skill.competences_api_map/1)} end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences",
        is_data_missing: &Enum.empty?(&1.experiences),
        data_map: fn data -> %{experiences: Enum.map(data, &Experience.experiences_api_map/1)} end
      }
    ] ++
      Enum.map(1..5, fn i ->
        # Since API called is limited to a 2 years interval, we need to fetch it 5 times to get 10 years
        start_date = Timex.shift(Timex.today(), years: -2 * i, days: 1)
        end_date = Timex.shift(Timex.today(), years: -2 * (i - 1))

        %{
          url:
            "https://api.emploi-store.fr/partenaire/peconnect-experiencesprofessionellesdeclareesparlemployeur/v1/contrats?dateDebutPeriode=#{
              Timex.format!(start_date, "{YYYY}{0M}{0D}")
            }&dateFinPeriode=#{Timex.format!(end_date, "{YYYY}{0M}{0D}")}",
          is_data_missing: fn user ->
            Enum.empty?(
              Enum.filter(user.proven_experiences, fn exp ->
                Timex.between?(exp.start_date, start_date, end_date)
              end)
            )
          end,
          data_map: fn data ->
            %{
              proven_experiences:
                Enum.filter(
                  Enum.map(
                    data["contrats"],
                    &ProvenExperience.experiencesprofessionellesdeclareesparlemployeur_api_map/1
                    # To make sure `is_data_missing` works properly,
                    # we need to make sure that proven experiences match only one query, instead of
                    # multiple in the API behavior.
                    # Hence the filtering over the results
                  ),
                  fn exp -> Timex.between?(exp.start_date, start_date, end_date) end
                )
            }
          end
        }
      end)
  end

  def fill_with_api_fields(initial_status, client_with_token, left_retries \\ 0) do
    try do
      Enum.reduce(build_api_calls(), initial_status, fn
        call, {:ok, user} = status ->
          if call.is_data_missing.(user) do
            IO.puts("Calling #{call.url}")
            api_result = OAuth.get(client_with_token, call.url)
            changeset = __MODULE__.changeset(user, call.data_map.(api_result.body))
            Repo.update(changeset)
          else
            status
          end

        _call, error ->
          error
      end)
    rescue
      error ->
        case left_retries do
          0 ->
            {:error, error}

          _n ->
            __MODULE__.fill_with_api_fields(initial_status, client_with_token, left_retries - 1)
        end
    end
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
