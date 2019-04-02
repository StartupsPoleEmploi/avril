defmodule Vae.Application do
  use Vae.Web, :model

  schema "applications" do
    belongs_to :user, Vae.User, foreign_key: :user_id
    belongs_to :delegate, Vae.Delegate, foreign_key: :delegate_id
    belongs_to :certification, Vae.Certification, foreign_key: :certification_id

    timestamps()
  end

  @fields ~w(user_id delegate_id certification_id)a

  def changeset(struct, params \\%{}) do
    struct
    |> cast(params, @fields)
  end
end
