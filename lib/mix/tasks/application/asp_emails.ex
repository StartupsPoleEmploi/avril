defmodule Mix.Tasks.Application.AspEmails do
  use Mix.Task

  import Mix.Ecto
  import Ecto.Query, only: [from: 2]

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    query = from a in Vae.Application, where: is_nil(a.submitted_at)
    Enum.map(Vae.Repo.all(query), &Vae.Application.maybe_autosubmit/1)
  end
end
