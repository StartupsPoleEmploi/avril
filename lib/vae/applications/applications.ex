defmodule Vae.Applications do
  import Ecto.Query

  alias Vae.{Certification, Delegate, UserApplication}
  alias Vae.Repo

  @doc "Lists applications from a User ID"
  def get_applications(user_id) do
    base_query()
    |> build_query(user_id: user_id)
    |> Repo.all()
  end

  @doc "Returns an application from its ID and user ID"
  def get_application_from_id_and_user_id(application_id, user_id) do
    base_query()
    |> build_query(application_id: application_id, user_id: user_id)
    |> Repo.one()
  end

  @doc "Attaches a delegate to an application"
  def attach_delegate(application, delegate) do
    application
    |> UserApplication.attach_delegate_changeset(delegate)
    |> Repo.update()
  end

  defp base_query() do
    from(a in UserApplication,
      join: c in Certification,
      on: a.certification_id == c.id,
      left_join: d in Delegate,
      on: a.delegate_id == d.id,
      preload: [delegate: d, certification: c]
    )
  end

  defp build_query(query, criterion) do
    Enum.reduce(criterion, query, &compose_query/2)
  end

  defp compose_query({:application_id, id}, query) do
    where(query, [a], a.id == ^id)
  end

  defp compose_query({:user_id, user_id}, query) do
    where(query, [a], a.user_id == ^user_id)
  end
end
