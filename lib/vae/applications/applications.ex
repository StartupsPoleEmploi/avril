defmodule Vae.Applications do
  import Ecto.Query

  alias Vae.{Certification, Delegate, UserApplication}
  alias Vae.Repo

  def get_applications(user_id) do
    from(a in UserApplication,
      join: c in Certification,
      on: a.certification_id == c.id,
      join: d in Delegate,
      on: a.delegate_id == d.id,
      where: a.user_id == ^user_id,
      preload: [delegate: d, certification: c]
    )
    |> Repo.all()
  end
end
