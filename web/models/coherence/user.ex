defmodule Vae.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  alias Vae.{Skill, Experience, ProvenExperience, JobSeeker, Application, Repo, Authentication}

  schema "users" do
    field(:name, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
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
    field(:pe_id, :string)
    field(:pe_connect_token, :string)
    belongs_to(:job_seeker, JobSeeker, on_replace: :update)

    has_many(:applications, Application, on_replace: :delete)
    has_one(:current_application, Application, on_replace: :delete)

    has_one(
      :current_delegate,
      through: [:current_application, :delegate]
    )

    has_one(
      :current_certification,
      through: [:current_application, :certification]
    )

    embeds_many(:skills, Skill, on_replace: :delete)
    embeds_many(:experiences, Experience, on_replace: :delete)
    embeds_many(:proven_experiences, ProvenExperience, on_replace: :delete)

    coherence_schema()

    timestamps()
  end

  @fields ~w(name first_name last_name email postal_code address1 address2 address3 address4 insee_code country_code city_label country_label pe_id pe_connect_token)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields ++ coherence_fields())
    |> cast_embed(:skills)
    |> cast_embed(:experiences)
    |> cast_embed(:proven_experiences)
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

  def create_or_associate_with_pe_connect_data(client_with_token, userinfo_api_result) do
    api_calls = [
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees",
        data_map: &__MODULE__.coordonnees_api_map/1
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences",
        data_map: fn data ->
          %{
            skills: Enum.map(data, &Skill.competences_api_map/1)
          }
        end
      },
      %{
        url: "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences",
        data_map: fn data ->
          %{
            experiences: Enum.map(data, &Experience.experiences_api_map/1)
          }
        end
      },
      %{
        # TODO: fetch longer periods
        url:
          "https://api.emploi-store.fr/partenaire/peconnect-experiencesprofessionellesdeclareesparlemployeur/v1/contrats?dateDebutPeriode=20170401&dateFinPeriode=20190401",
        data_map: fn data ->
          %{
            proven_experiences:
              Enum.map(
                data["contrats"],
                &ProvenExperience.experiencesprofessionellesdeclareesparlemployeur_api_map/1
              )
          }
        end
      }
    ]

    initial_status =
      case Repo.get_by(__MODULE__, email: String.downcase(userinfo_api_result["email"])) do
        nil ->
          Repo.insert(
            __MODULE__.changeset(%__MODULE__{}, __MODULE__.userinfo_api_map(userinfo_api_result))
          )

        user ->
          Repo.update(
            __MODULE__.changeset(user, __MODULE__.userinfo_api_map(userinfo_api_result, false))
          )
      end

    case Enum.reduce(api_calls, initial_status, fn
           call, {:ok, user} ->
             IO.puts("Calling #{call.url}")
             api_result = Authentication.get(client_with_token, call.url)
             changeset = __MODULE__.changeset(user, call.data_map.(api_result.body))
             Repo.update(changeset)

           _call, error ->
             error
         end) do
      {:ok, user} -> user
      {:error, _changeset} -> nil
    end

    # changeset =
    # case  do
    #   {:error, changeset} -> nil
    #   {:ok, user} ->
    # end

    # Enum.reduce(api_calls, %User{}, fn call, user ->

    # {user, extra_params} = if user == nil do
    #   tmp_password = "AVRIL_#{api_result.body["idIdentiteExterne"]}_TMP_PASSWORD"
    #   case Repo.get_by(User, pe_id: api_result.body["idIdentiteExterne"]) do
    #     nil -> {%User{}, %{
    #       "email" => String.downcase(api_result.body["email"]),
    #       "password" => tmp_password,
    #       "password_confirmation" => tmp_password,
    #     }}
    #     user -> { user |> Repo.preload(:job_seeker), nil } # User exists, let's use it
    #   end
    # else
    #   {user, nil}
    # end

    #   actual_changeset_params = unless is_nil(extra_params), do: Map.merge(api_result.body, extra_params), else: api_result.body

    #   changeset = User.changeset(user, call.changeset.(actual_changeset_params))

    #   application = case Repo.insert_or_update(changeset) do
    #     {:ok, user} ->
    #       application_params = Map.merge(get_certification_id_and_delegate_id_from_referer(get_session(conn, :referer)), %{
    #         user_id: user.id
    #         })
    #       case existing_application = Repo.get_by(Application, application_params) do
    #         nil ->
    #           changeset = Application.changeset(%Application{}, application_params)
    #           case Repo.insert(changeset) do
    #             {:ok, application} -> user
    #             {:error, changeset} -> nil
    #           end
    #         existing_application -> existing_application
    #       end
    #     {:error, changeset} -> nil
    #   end

    # end)
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
end
