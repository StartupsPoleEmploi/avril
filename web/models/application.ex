defmodule Vae.Application do
  require Logger

  use Vae.Web, :model

  alias Vae.{
    ApplicationEmail,
    Certification,
    Delegate,
    Meetings.Meeting,
    Mailer,
    Repo,
    Resume,
    User
  }

  schema "applications" do
    # Triggers an analytics event at the front
    field(:has_just_been_auto_submitted, :boolean, virtual: true)
    field(:submitted_at, :utc_datetime)
    field(:delegate_access_refreshed_at, :utc_datetime)
    field(:delegate_access_hash, :string)
    field(:admissible_at, :utc_datetime)
    field(:inadmissible_at, :utc_datetime)
    field(:booklet_hash, :string)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:delegate, Delegate, foreign_key: :delegate_id)
    belongs_to(:certification, Certification, foreign_key: :certification_id)

    has_many(:resumes, Resume, on_delete: :delete_all)

    has_many(
      :certifiers,
      through: [:certification, :certifiers]
    )

    embeds_one(:meeting, Meeting, on_replace: :delete)
    embeds_one(:booklet_1, Vae.Booklet.Cerfa, on_replace: :delete)

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at delegate_access_refreshed_at delegate_access_hash has_just_been_auto_submitted)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> init_booklet_hash()
  end

  def init_booklet_hash(changeset) do
    change(changeset, booklet_hash: changeset.data.booklet_hash || generate_hash(64))
  end

  def find_or_create_with_params(
        %{user_id: user_id, delegate_id: delegate_id, certification_id: certification_id} = params
      )
      when not is_nil(user_id) and not is_nil(delegate_id) and not is_nil(certification_id) do
    case Repo.get_by(__MODULE__, params) do
      nil -> Repo.insert(changeset(%__MODULE__{}, params))
      application -> {:ok, application}
    end
  end

  def submit(application, auto_submitted \\ false) do
    application = Repo.preload(application, [:user, :delegate])

    case User.submit_application_required_missing_fields(application.user) do
      [] ->
        if is_nil(application.submitted_at) do
          with(
            {:ok, application} <-
              Repo.update(
                __MODULE__.changeset(application, %{
                  delegate_access_hash: generate_hash(64),
                  delegate_access_refreshed_at: DateTime.utc_now()
                })
              ),
            {:ok, _messages} <-
              Mailer.send(
                if Delegate.is_asp?(application.delegate),
                  do: ApplicationEmail.asp_user_submission_confirmation(application),
                  else: [
                    ApplicationEmail.delegate_submission(application),
                    ApplicationEmail.user_submission_confirmation(application)
                  ]
              )
          ) do
            Repo.update(
              __MODULE__.changeset(application, %{
                has_just_been_auto_submitted: auto_submitted,
                submitted_at: DateTime.utc_now()
              })
            )
          else
            error -> error
          end
        else
          {:ok, application}
        end

      missing_fields ->
        {:error, "Remplissez d'abord les données manquantes : #{Enum.join(missing_fields, ", ")}"}
    end
  end

  def list_from_last_month(%Date{} = end_date) do
    start_date = Vae.JobSeeker.get_previous_month(end_date)

    from(a in __MODULE__,
      where: fragment("(?)::timestamp::date", a.submitted_at) == ^start_date,
      preload: [user: [:job_seeker], delegate: [:certifiers]]
    )
    |> Repo.all()
  end

  def submitted_now(application) do
    application
    |> change(%{submitted_at: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update!()
  end

  def admissible_now(application) do
    application
    |> change(admissible_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update!()
  end

  def inadmissible_now(application) do
    application
    |> change(inadmissible_at: DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update!()
  end

  def register_meeting(application, nil), do: {:ok, application}

  def register_meeting(application, meeting_id) do
    case Vae.Meetings.register(meeting_id, application) do
      {:ok, meeting} ->
        application
        |> change()
        |> put_embed(:meeting, meeting)
        |> Repo.update()

      {:error, _meeting} = error ->
        error
    end
  end

  def save_booklet(application, booklet_params) do
    application
    |> change()
    # |> cast(%{"booklet_1" => booklet_params}, [])
    # |> cast_embed(:booklet_1)
    |> put_embed(
      :booklet_1,
      Vae.Booklet.Cerfa.changeset(
        application.booklet_1 || %Vae.Booklet.Cerfa{},
        booklet_params
      )
    )
    |> Repo.update()
  end

  # def put_booklet(application, booklet) do
  #   application
  #   |> change()
  #   |> put_embed(:booklet_1, booklet)
  #   |> Repo.update()
  # end

  def reset_booklet(application) do
    application
    |> change()
    |> put_embed(:booklet_1, nil)
    |> Repo.update()
  end

  def certifier_name(application) do
    application
    |> Repo.preload(delegate: :certifiers)
    |> get_in([Access.key(:delegate), Access.key(:certifiers)])
    |> hd()
    |> Map.get(:name)
  end

  def booklet_url(application, path \\ '/') do
    application = application |> Repo.preload(:delegate)

    cond do
      Delegate.is_asp?(application.delegate) ->
        "https://vaedem.asp-public.fr/vaedem/creationCompte.html"

      Delegate.is_educ_nat?(application.delegate) ->
        booklet_url!(application, path)

      true ->
        nil
    end
  end

  def booklet_url!(application, path \\ '/') do
    if System.get_env("NUXT_PATH"),
      do: "#{System.get_env("NUXT_PATH")}#{path}?hash=#{application.booklet_hash}",
      else: Logger.warn("NUXT_PATH environment variable not set") && nil
  end

  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
