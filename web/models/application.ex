defmodule Vae.Application do
  use Vae.Web, :model

  alias Vae.Repo
  alias Vae.Mailer.Sender.Mailjet
  alias Vae.Email
  alias Vae.ApplicationEmail

  schema "applications" do
    field(:has_just_been_auto_submitted, :boolean, virtual: true) # Triggers an analytics event at the front
    field(:submitted_at, :utc_datetime)
    field(:delegate_access_refreshed_at, :utc_datetime)
    field(:delegate_access_hash, :string)
    belongs_to(:user, Vae.User, foreign_key: :user_id)
    belongs_to(:delegate, Vae.Delegate, foreign_key: :delegate_id)
    belongs_to(:certification, Vae.Certification, foreign_key: :certification_id)

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at delegate_access_refreshed_at delegate_access_hash has_just_been_auto_submitted)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def find_or_create_with_params(%{user_id: user_id, delegate_id: delegate_id, certification_id: certification_id} = params) do
    Repo.get_by(__MODULE__, params) || case Repo.insert(__MODULE__.changeset(%__MODULE__{}, params)) do
      {:ok, application} -> application |> __MODULE__.submit_if_asp()
      {:error, msg} -> nil
    end
  end
  def find_or_create_with_params(params), do: nil

  def submit(application, auto_submitted\\false) do
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
          {:ok, message} ->
            Repo.update(
              __MODULE__.changeset(application, %{
                has_just_been_auto_submitted: auto_submitted,
                submitted_at: DateTime.utc_now()
              })
            )
          error -> error
        end
      error -> error
    end
  end

  def submit_if_asp(application) do
    if __MODULE__.is_asp(application) do
      case __MODULE__.submit(application, true) do
        {:ok, application} -> application
        {:error, msg} -> nil
      end
    else
      application
    end
  end

  def is_asp(application) do
    application = Repo.preload(application, :delegate)
    Vae.Delegate.is_asp(application.delegate)
  end

  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end
end
