defmodule Vae.Resume do
  use Ecto.Schema
  import Ecto.Changeset
  alias Vae.Repo

  alias __MODULE__

  schema "resumes" do
    field(:content_type, :string)
    field(:filename, :string)
    field(:url, :string)

    timestamps()

    belongs_to(:application, Vae.UserApplication, foreign_key: :application_id)
  end

  @doc false
  def changeset(resume, attrs) do
    resume
    |> cast(attrs, [:filename, :content_type, :url])
    |> put_assoc(:application, attrs[:application])
    |> validate_required([:filename, :content_type, :url, :application])
  end

  def create(application, params) do
    filename = "#{UUID.uuid4(:hex)}#{Path.extname(params.filename)}"
    {:ok, binary} = File.read(params.path)

    result =
      ExAws.S3.put_object(
        Application.get_env(:ex_aws, :s3)[:bucket],
        to_s3_path(application.id, filename),
        binary,
        content_type: params.content_type,
        content_disposition: "attachment; filename=#{params.filename}"
      )
      |> ExAws.request()

    case result do
      {:ok, body} ->
        Repo.insert(
          Resume.changeset(%Resume{}, %{
            application: application,
            content_type: params.content_type,
            filename: params.filename,
            url:
              "http://localhost:9000/#{Application.get_env(:ex_aws, :s3)[:bucket]}#{
                to_s3_path(application.id, filename)
              }"
          })
        )

      error ->
        error
    end
  end

  def delete(resume) do
    result =
      ExAws.S3.delete_object(
        Application.get_env(:ex_aws, :s3)[:bucket],
        to_s3_path(resume)
      )
      |> ExAws.request()

    case result do
      {:ok, _body} ->
        Repo.delete(resume)

      error ->
        error
    end
  end

  def to_s3_path(application_id, filename), do: "/#{application_id}/#{filename}"

  def to_s3_path(%Resume{application_id: application_id, url: url}),
    do: to_s3_path(application_id, List.last(String.split(url, "/")))
end
