# TODO: remove this
defmodule Vae.Applications do
  import Ecto.Query

  alias Vae.{
    Booklet,
    Certification,
    Delegate,
    Meeting,
    Meetings,
    Repo,
    Resume,
    User,
    UserApplication
  }

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

  @doc "Retrieve a resume from its ID and user ID"
  def get_resume_from_id_and_user_id(resume_id, user_id) do
    from(r in Resume,
      join: a in UserApplication,
      on: r.application_id == a.id,
      join: u in User,
      on: a.user_id == u.id,
      where: r.id == ^resume_id and u.id == ^user_id,
      select: r
    )
    |> Repo.one()
  end

  @doc "Attaches a delegate to an application"
  def attach_delegate(application, delegate) do
    application
    |> UserApplication.attach_delegate_changeset(delegate)
    |> Repo.update()
  end

  @doc "Attaches a resume to an application"
  def attach_resume_to_application(application, resume_file) do
    application
    |> UserApplication.attach_resume_changeset(resume_file)
    |> Repo.update()
  end

  @doc "Register a user's application to a meeting"
  def register_to_a_meeting(_application, meeting_id) when meeting_id in [nil, ""],
    do: {:error, "You must provide a meeting_id"}

  def register_to_a_meeting(application, meeting_id) do
    with(
      %UserApplication{user: user, delegate: delegate} = application <- Repo.preload(application, [:delegate, :user, :meeting]),
      {:ok, _valid} <- User.can_submit_or_register?(user),
      {:ok, %Meeting{} = meeting} <- {:ok, Meeting.get_by_meeting_id(Delegate.get_meeting_source(delegate), meeting_id)},
      {:ok, _message} <- Meetings.register(meeting, application)
    ) do
      application
      |> UserApplication.register_meeting_changeset(meeting)
      |> Repo.update()
    else
      error ->
        {:error, error}
    end
  end

  @doc "Generate an hash access to an application for a delegate"
  def generate_delegate_access_hash(%UserApplication{delegate_access_hash: nil} = application) do
    application
    |> UserApplication.generate_delegate_access_hash_changeset()
    |> Repo.update()
  end

  def generate_delegate_access_hash(application), do: {:ok, application}

  @doc "Set the date and time at which the confirmation was sent"
  def set_meeting_submitted_at(application) do
    application
    |> UserApplication.meeting_submitted_at_changeset()
    |> Repo.update()
  end

  @doc "Prepare the application before sending to the delegate"
  def prepare_submit(%UserApplication{submitted_at: nil} = application) do
    with {:ok, _valid} <- User.can_submit_or_register?(application.user) do
      generate_delegate_access_hash(application)
    else
      error ->
        error
    end
  end

  def prepare_submit(application), do: {:ok, application}

  @doc "Set submitted at"
  def set_submitted_now(%UserApplication{submitted_at: nil} = application) do
    application
    |> UserApplication.submitted_now_changeset()
    |> Repo.update()
  end

  def set_submitted_now(application), do: {:ok, application}

  def set_raised_now(%UserApplication{} = application) do
    application
    |> UserApplication.raised_now_changeset()
    |> Repo.update()
  end

  def delete_resume(resume), do: Resume.delete(resume)

  def get_booklet(application) do
    booklet =
      (application.booklet_1 || Booklet.from_application(application))
      |> with_static_fields(application)

    {:ok, booklet}
  end

  def with_static_fields(booklet, application) do
    application = Repo.preload(application, [certification: :romes])

    booklet
    |> Map.put(:certification_romes, application.certification.romes)
    |> Map.put(:certification_name, Certification.name(application.certification))
    |> Map.put(:certifier_name, UserApplication.certifier_name(application))
  end

  def set_booklet(application, booklet) do
    UserApplication.save_booklet(application, booklet)
    |> Repo.update()
  end

  defp base_query() do
    from(a in UserApplication)
    |> preload([[delegate: :certifiers], [certification: :certifiers], :user, :resumes, :meeting])
    # from(a in UserApplication,
    #   join: c in Certification,
    #   on: a.certification_id == c.id,
    #   left_join: d in Delegate,
    #   on: a.delegate_id == d.id,
    #   left_join: u in User,
    #   on: a.user_id == u.id,
    #   left_join: r in Resume,
    #   on: a.id == r.application_id,
    #   preload: [delegate: d, certification: c, user: u, resumes: r]
    # )
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
