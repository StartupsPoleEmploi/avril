defmodule Mix.Tasks.MigrateS3ToMinio do
  require Logger
  use Mix.Task

  import Ecto.Query

  alias Vae.{Repo, Resume}

  def run(_args) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Vae.Repo.start_link()

    query = from r in Resume
    stream = Repo.stream(query)

    Repo.transaction(fn ->
      stream
      |> Repo.stream_preload(200, [:application])
      |> Enum.each(&upgrade_url_if_necessary/1)
    end)
  end

  def upgrade_url_if_necessary(%Resume{url: url} = resume) do
    if String.contains?(url, "amazonaws.com") do
      Resume.changeset(resume, %{
        url: Resume.file_url(Vae.URI.endpoint(), resume)
      }) |> Repo.update()
    end
  end
end
