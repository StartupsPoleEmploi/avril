defmodule Vae.Application do
  use Vae.Web, :model

  alias Vae.Repo
  alias Vae.Mailer.Sender.Mailjet
  alias Vae.Email
  alias Vae.ApplicationEmail


  schema "applications" do
    field :submitted_at, :utc_datetime
    field :delegate_access_refreshed_at, :utc_datetime
    field :delegate_access_hash, :string
    belongs_to :user, Vae.User, foreign_key: :user_id
    belongs_to :delegate, Vae.Delegate, foreign_key: :delegate_id
    belongs_to :certification, Vae.Certification, foreign_key: :certification_id

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at delegate_access_refreshed_at delegate_access_hash)a

  def changeset(struct, params \\%{}) do
    struct
    |> cast(params, @fields)
  end

  def create_with_params(params) do
    case Repo.insert(__MODULE__.changeset(%__MODULE__{}, params)) do
      {:ok, application} -> application
      error -> nil
    end
  end

  def submit(application) do
    case Repo.update(__MODULE__.changeset(application, %{
      delegate_access_hash: generate_hash(64),
      delegate_access_refreshed_at: DateTime.utc_now(),
    })) do
      {:ok, application} ->
        case Email.send([
          ApplicationEmail.delegate_submission(application),
          ApplicationEmail.user_submission_confirmation(application)
        ]) do
          {:ok, message} -> Repo.update(__MODULE__.changeset(application, %{
            submitted_at: DateTime.utc_now()
            }))
          error -> error
        end
      error -> error
    end
  end

  defp generate_hash(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
