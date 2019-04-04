defmodule Vae.Application do
  use Vae.Web, :model

  alias Vae.Repo

  schema "applications" do
    field :submitted_at, :utc_datetime
    belongs_to :user, Vae.User, foreign_key: :user_id
    belongs_to :delegate, Vae.Delegate, foreign_key: :delegate_id
    belongs_to :certification, Vae.Certification, foreign_key: :certification_id

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id submitted_at)a

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
end
