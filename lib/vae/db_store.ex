defimpl Coherence.DbStore, for: Vae.User do
  alias Vae.Repo
  alias Vae.EctoDbSession

  def get_user_data(user, creds, id_key),
    do: EctoDbSession.get_user_data(Repo, user, creds, id_key)

  def put_credentials(user, creds, id_key),
    do: EctoDbSession.put_credentials(Repo, user, creds, id_key)

  def delete_credentials(user, creds),
    do: EctoDbSession.delete_credentials(user, creds)
end