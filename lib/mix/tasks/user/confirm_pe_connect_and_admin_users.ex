defmodule Mix.Tasks.User.ConfirmPEConnectAndAdminUsers do
  use Mix.Task

  require Logger

  import Ecto.Query

  alias Vae.{Repo, User}

  @shortdoc "Confirm existing PE Connect and admin users"
  def run(_args) do
    # ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)
    from(u in User, where: is_nil(u.email_confirmed_at) and u.is_admin)
    |> Repo.update_all(set: [email_confirmed_at: Timex.now()])

    from(u in User, where: is_nil(u.email_confirmed_at) and not is_nil(u.pe_id))
    |> Repo.update_all(set: [email_confirmed_at: Timex.now()])
  end

end
