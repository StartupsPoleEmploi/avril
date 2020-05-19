defmodule Vae.UserApplication do
  require Logger

  use VaeWeb, :model

  alias VaeWeb.ApplicationEmail
  alias VaeWeb.Mailer

  alias Vae.{
    Certifier,
    Certification,
    Delegate,
    Meetings.Meeting,
    Resume,
    User
  }

  alias Vae.Repo

  alias __MODULE__

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
    belongs_to(:delegate, Delegate, foreign_key: :delegate_id, on_replace: :nilify)
    belongs_to(:certification, Certification, foreign_key: :certification_id)

    has_many(:resumes, Resume, on_delete: :delete_all, foreign_key: :application_id)

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

  def attach_delegate_changeset(struct, %Delegate{} = delegate) do
    struct
    |> change()
    |> put_assoc(:delegate, delegate)
  end

  def attach_resume_changeset(struct, %Resume{} = resume) do
    struct
    |> change()
    |> put_assoc(:resumes, [resume | struct.resumes])
  end

  def register_meeting_changeset(struct, params) do
    struct
    |> change()
    |> put_embed(:meeting, params)
  end

  def init_booklet_hash(changeset) do
    change(changeset, booklet_hash: changeset.data.booklet_hash || generate_hash(64))
  end

  def find_or_create_with_params(%{user_id: user_id, certification_id: certification_id} = params)
      when not is_nil(user_id) and not is_nil(certification_id) do
    case Repo.get_by(__MODULE__, %{
           user_id: user_id,
           certification_id: certification_id
         }) do
      nil -> Repo.insert(changeset(%__MODULE__{}, params))
      application -> {:ok, application}
    end
  end
  def find_or_create_with_params(_params) do
    {:ok, nil}
  end

  def set_delegate(%UserApplication{} = application, %Delegate{id: id} = _delegate) do
    application
    |> change(%{delegate_id: id})
    |> Repo.update()
  end

  def generate_delegate_access_hash_changeset(application) do
    change(application, %{
      delegate_access_hash: generate_hash(64),
      delegate_access_refreshed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def meeting_submitted_at_changeset(application) do
    change(application, %{
      submitted_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
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

  def submitted_now_changeset(application) do
    change(application, %{submitted_at: DateTime.truncate(DateTime.utc_now(), :second)})
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

  def from_application_id_and_user_id(application_id, user_id) do
    from(
      a in __MODULE__,
      join: c in Certification,
      on: a.certification_id == c.id,
      # join: d in Delegate,
      # on: a.delegate_id == d.id,
      where: a.id == ^application_id and a.user_id == ^user_id,
      preload: [certification: c]
    )
    |> Repo.one()
  end

  def reset_booklet(application) do
    application
    |> change()
    |> put_embed(:booklet_1, nil)
    |> Repo.update()
  end

  def certifier_name(%UserApplication{} = application) do
    application
    |> Repo.preload(delegate: :certifiers)
    |> case do
      %UserApplication{delegate: %Delegate{certifiers: [%Certifier{name: name} | _rest]}} -> name
      _ -> nil
    end
  end

  def booklet_url(endpoint, application, path \\ nil) do
    application = application |> Repo.preload(:delegate)

    cond do
      application.delegate && Delegate.is_asp?(application.delegate) ->
        "https://vaedem.asp-public.fr/vaedem/creationCompte.html"

      true ->
        booklet_url!(endpoint, application, path)
    end
  end

  def booklet_url!(endpoint, application, path \\ nil) do
    if is_nil(System.get_env("NUXT_BOOKLET_PATH")) do
      Logger.warn("NUXT_BOOKLET_PATH environment variables not set")
    end

    %URI{
      path: "#{System.get_env("NUXT_BOOKLET_PATH")}#{path}",
      query: "hash=#{application.booklet_hash}"
    }
    |> Vae.URI.to_absolute_string(endpoint)
  end

  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
