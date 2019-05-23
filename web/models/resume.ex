defmodule Vae.Resume do
  use Ecto.Schema
  import Ecto.Changeset


  schema "resumes" do
    field :content_type, :string
    field :filename, :string

    timestamps()

    belongs_to(:application, Vae.Application, foreign_key: :application_id)

  end

  @doc false
  def changeset(resume, attrs) do
    resume
    |> cast(attrs, [:filename, :content_type])
    |> put_assoc(:application, attrs[:application])
    |> validate_required([:filename, :content_type, :application])
  end

  def web_path(resume), do: "/uploads/#{resume.filename}"
end
