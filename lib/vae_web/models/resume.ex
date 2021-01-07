defmodule Vae.Resume do
  use VaeWeb, :model
  require Logger

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

  def from_file_and_application_id(file, application_id) do
    %Resume{
      content_type: file.content_type,
      filename: file.filename,
      url: file_url(Vae.URI.endpoint(), application_id, file.filename)
    }
  end

  @doc false
  def changeset(resume, params \\ %{}) do
    resume
    |> cast(params, [:filename, :content_type, :url])
    |> put_param_assoc(:application, params)
    |> validate_required([:filename, :content_type, :url, :application])
  end

  def attach_resume_to_application(application, file) do
    filename = "#{UUID.uuid4(:hex)}#{Path.extname(file.filename)}"

    resume = %Resume{
      content_type: file.content_type,
      filename: file.filename,
      url: file_url(Vae.URI.endpoint(), application.id, filename)
    }

    with {:ok, content} <- File.read(file.path),
         {:ok, _result} <- store(application.id, filename, resume, content) do
      resume
    else
      {:error, error} -> Logger.error(fn -> inspect(error) end)
    end
  end

  def store(application_id, filename, resume, content) do
    ExAws.S3.put_object(
      Application.get_env(:ex_aws, :s3)[:bucket],
      file_path(application_id, filename),
      content,
      content_type: resume.content_type,
      content_disposition: "attachment; filename=#{resume.filename}"
    )
    |> ExAws.request()
  end

  def delete(resume) do
    result =
      ExAws.S3.delete_object(
        Application.get_env(:ex_aws, :s3)[:bucket],
        file_path(resume)
      )
      |> ExAws.request()

    case result do
      {:ok, _body} ->
        Repo.delete(resume)

      error ->
        error
    end
  end

  def file_url(endpoint, %Resume{application_id: application_id, url: url}),
    do: file_url(endpoint, application_id, List.last(String.split(url, "/")))

  def file_url(endpoint, application_id, filename) do
    %URI{
      path: "#{System.get_env("FILES_PATH")}/#{file_path(application_id, filename)}"
    }
    |> Vae.URI.to_absolute_string(endpoint)
  end

  defp file_path(%Resume{application_id: application_id, url: url}),
    do: file_path(application_id, List.last(String.split(url, "/")))

  defp file_path(application_id, filename),
    do: "#{application_id}/#{filename}"
end
