defmodule Vae.Repo.Migrations.SubmitAspApplications do
  use Ecto.Migration
  import Ecto.Query, only: [from: 2]

  def up do

    query = from a in Vae.Application, where: not is_nil(a.submitted_at)
    Enum.map(Vae.Repo.all(query), &Vae.Application.maybe_autosubmit/1)
  end

  def down do
  end
end
