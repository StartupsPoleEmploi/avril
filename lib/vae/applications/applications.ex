defmodule Vae.Applications do
  import Ecto.Query

  alias Vae.UserApplication
  alias Vae.Repo

  def get_applications(user_id) do
    from(a in UserApplication,
      where: a.user_id == ^user_id
    )
    |> Repo.all()
  end
end
