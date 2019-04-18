defmodule Vae.Repo.Migrations.MakeExistingUsersAdmin do
  use Ecto.Migration

  alias Vae.{Repo, User}
  import Ecto.Query

  def up do
    set_is_admin_to_existing_users = from(u in User, update: [set: [is_admin: true]])
    Repo.update_all(set_is_admin_to_existing_users, [])
  end

  def down do
  end
end
