defmodule Vae.Applications do
  import Ecto.Query

  alias Vae.{Account, Certification, Delegate, Meetings, UserApplication}
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

  @doc "Register a user's application to a meeting"
  def register_to_a_meeting(application, meeting_id) when meeting_id in [nil, ""],
    do: {:error, "You must provide a meeting_id"}

  def register_to_a_meeting(application, meeting_id) do
    with user <- Account.get_user(application.user_id),
         {:ok, valid} <-
           Account.validate_required_fields_to_register_meeting(user),
         {:ok, meeting} <-
           Meetings.register(meeting_id, application) do
      application
      |> UserApplication.register_meeting_changeset(meeting)
      |> Repo.update()
    else
      {:error, _msg} = error ->
        error

      error ->
        {:error, error}
    end
  end

  @doc "Generate an hash access to an application for a delegate"
  def generate_delegate_access_hash(application) do
    application
    |> UserApplication.generate_delegate_access_hash_changeset()
    |> Repo.update()
  end

  @doc "Set the date and time at which the confirmation was sent"
  def set_meeting_submitted_at(application) do
    application
    |> UserApplication.meeting_submitted_at_changeset()
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