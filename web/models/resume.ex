defmodule Vae.Resume do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resumes" do
    field :content_type, :string
    field :filename, :string
    field :url, :string

    timestamps()

    belongs_to(:application, Vae.Application, foreign_key: :application_id)
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

    IO.inspect(Application.get_env(:ex_aws, :bucket_name))
    IO.inspect(filename)

    result =
      ExAws.S3.put_object(Application.get_env(:ex_aws, :bucket_name), filename, binary)
      |> ExAws.request

    case result do
      {:ok, body} ->
        Repo.insert(__MODULE__.changeset(%{
          application: application,
          content_type: params.content_type,
          filename: params.filename,
          url: "https://#{Application.get_env(:ex_aws, :bucket_name)}.s3.amazonaws.com/#{Application.get_env(:ex_aws, :bucket_name)}/#{filename}"
        }))
      error -> error
    end

    IO.inspect(result)

  end

  def delete(resume) do
    result =
      ExAws.S3.delete_object(Application.get_env(:ex_aws, :bucket_name), List.last(String.split(resume.url, "/")))
      |> ExAws.request

    IO.inspect(result)

    Repo.delete(resume)
  end

end
