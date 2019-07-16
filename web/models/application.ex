defmodule Vae.Application do
  require Logger

  use Vae.Web, :model

  alias Vae.{ApplicationEmail, Certification, Delegate, Delegates.FranceVae.Meeting, Email, Repo, Resume, User}

  schema "applications" do
    # Triggers an analytics event at the front
    field(:has_just_been_auto_submitted, :boolean, virtual: true)
    field(:submitted_at, :utc_datetime)
    field(:delegate_access_refreshed_at, :utc_datetime)
    field(:delegate_access_hash, :string)
    field(:admissible_at, :utc_datetime)
    field(:inadmissible_at, :utc_datetime)

    belongs_to(:user, User, foreign_key: :user_id)
    belongs_to(:delegate, Delegate, foreign_key: :delegate_id)
    belongs_to(:certification, Certification, foreign_key: :certification_id)

    has_many(:resumes, Resume, on_delete: :delete_all)

    has_many(
      :certifiers,
      through: [:certification, :certifiers]
    )

    embeds_one(:meeting, Meeting, on_replace: :delete)

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at delegate_access_refreshed_at delegate_access_hash has_just_been_auto_submitted)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def find_or_create_with_params(
        %{user_id: _user_id, delegate_id: _delegate_id, certification_id: _certification_id} =
          params
      ) do
    Repo.get_by(__MODULE__, params) ||
      case Repo.insert(__MODULE__.changeset(%__MODULE__{}, params)) do
        {:ok, application} ->
          application

        {:error, msg} ->
          Logger.error(fn -> inspect(msg) end)
          nil
      end
  end

  def find_or_create_with_params(_params), do: nil

  def submit(application, auto_submitted \\ false) do
    case application.submitted_at do
      nil ->
        case Repo.update(
               __MODULE__.changeset(application, %{
                 delegate_access_hash: generate_hash(64),
                 delegate_access_refreshed_at: DateTime.utc_now()
               })
             ) do
          {:ok, application} ->
            case Email.send([
                   ApplicationEmail.delegate_submission(application),
                   ApplicationEmail.user_submission_confirmation(application)
                 ]) do
              {:ok, _message} ->
                Repo.update(
                  __MODULE__.changeset(application, %{
                    has_just_been_auto_submitted: auto_submitted,
                    submitted_at: DateTime.utc_now()
                  })
                )

              error ->
                error
            end

          error ->
            error
        end

      _ ->
        {:ok, application}
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
    |> change(%{submitted_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  def admissible_now(application) do
    application
    |> change(admissible_at: DateTime.utc_now())
    |> Repo.update!()
  end

  def inadmissible_now(application) do
    application
    |> change(inadmissible_at: DateTime.utc_now())
    |> Repo.update!()
  end

  def set_registered_meeting(application, _academy_id, nil), do: {:ok, application}
  def set_registered_meeting(application, academy_id, meeting_id) do
    meeting = Vae.Delegates.get_france_vae_meetings(
      application.delegate.academy_id
    ) |> Enum.find(fn meeting -> meeting.meeting_id == String.to_integer(meeting_id) end)
    application
    |> change()
    |> put_embed(:meeting, meeting)
    |> Repo.update()
  end

  defp put_meeting(changeset, meeting) do
    changeset
    |> put_embed(:meeting, Meeting.changeset(meeting, %{}))
  end

  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

end
