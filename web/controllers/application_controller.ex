defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller

  alias Vae.{Application, Resume, User}
  alias Vae.Crm.Polls

  plug Vae.Plugs.ApplicationAccess when action not in [:show, :admissible, :inadmissible]
  plug Vae.Plugs.ApplicationAccess, [allow_hash_access: true] when action in [:show]

  def show(conn, %{"id" => _id} = params) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([
        :user,
        [delegate: [:process, :certifiers]],
        :certification,
        :resumes
      ])

    meetings =
      if application.meeting,
        do: [],
        else: Vae.Meetings.get(application.delegate)

    preselected_place =
      if length(meetings) > 0,
        do: meetings |> List.first() |> elem(0)

    render(conn, "show.html", %{
      title:
        "Candidature VAE de #{application.user.name} pour un diplôme de #{
          application.certification.label
        }",
      application: application,
      delegate: application.delegate,
      certification: application.certification,
      user: application.user,
      grouped_experiences:
        application.user.proven_experiences
        |> Enum.group_by(fn exp -> {exp.company_name, exp.label} end)
        |> Vae.Map.map_values(fn {_k, experiences} ->
          Enum.sort_by(experiences, fn exp -> Date.to_erl(exp.start_date) end, &>/2)
        end)
        |> Map.to_list()
        |> Enum.sort_by(fn {_k, v} -> Date.to_erl(List.first(v).start_date) end, &>/2),
      edit_mode:
        params["mode"] != "certificateur" &&
          Coherence.logged_in?(conn) && Coherence.current_user(conn).id == application.user.id,
      user_changeset: User.changeset(application.user, %{}),
      resume_changeset: Resume.changeset(%Resume{}, %{}),
      application_changeset: Application.changeset(application, %{}),
      preselected_place: preselected_place,
      meetings: meetings
    })
  end

  # TODO: change to submit
  def update(conn, %{"id" => id} = params) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([
        :user,
        [delegate: [:process, :certifiers]],
        :certification
      ])
    meeting_id = if params["book"] == "on" && params["application"]["meeting_id"],
      do: String.to_integer(params["application"]["meeting_id"])

    [
      fn application ->
        case Vae.Meetings.register(meeting_id, application) do
          {:ok, meeting} ->
            Application.set_registered_meeting(application, meeting)
          {:error, _error} = error -> error
        end
      end,
      fn application -> Application.submit(application) end
    ]
    |> Enum.reduce({:ok, application}, fn
      function, {:ok, application} -> function.(application)
      _function, {:error, _} = error -> error
    end)
    |> case do
      {:ok, application} ->
        if application.meeting && (application.meeting.name == :france_vae) do
          redirect(conn,
            to:
              Routes.application_france_vae_redirect_path(
                conn,
                :france_vae_redirect,
                application,
                %{
                  academy_id: application.delegate.academy_id,
                  meeting_id: application.meeting.meeting_id
                }
              )
          )
        else
          conn
            |> put_flash(:succes, "Dossier transmis avec succès !")
            |> redirect(to: Routes.application_path(conn, :show, application))
        end
      {:error, msg} ->
        Logger.error(fn -> inspect(msg) end)

        conn
          |> put_flash(:error, "Une erreur est survenue, merci de réessayer plus tard")
          |> redirect(to: Routes.application_path(conn, :show, application))
    end
  end

  def download(conn, %{"application_id" => id}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([
        :user,
        [delegate: [:process, :certifiers]],
        :certification
      ])

    case Vae.StepsPdf.create_pdf_file(application.delegate.process) do
      {:ok, file} ->
        conn
        |> put_resp_content_type("application/pdf", "utf-8")
        |> send_file(200, file)

      {:error, msg} ->
        conn
        |> put_flash(:error, "Une erreur est survenue: #{msg}. Merci de réessayer plus tard.")
        |> redirect(to: Routes.application_path(conn, :show, application))
    end
  end

  def admissible(conn, %{"id" => id}) do
    Repo.get(Application, id)
    |> case do
      nil ->
        redirect(conn, to: Routes.root_path(conn, :index))

      application ->
        Application.admissible_now(application)

        conn
        |> put_flash(:success, "Merci pour votre réponse")
        |> redirect(to: Routes.root_path(conn, :index))
    end
  end

  def inadmissible(conn, %{"id" => id}) do
    Repo.get(Application, id)
    |> Repo.preload(delegate: :certifiers)
    |> case do
      nil ->
        redirect(conn, to: Routes.root_path(conn, :index))

      application ->
        Application.inadmissible_now(application)

        url_form = Polls.define_form_url_from_application(application)

        conn
        |> redirect(external: url_form || Routes.root_path(conn, :index))
    end
  end

  def france_vae_redirect(
        conn,
        %{
          "application_id" => _id,
          "academy_id" => academy_id
        } = params
      ) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user, {:delegate, :process}, :certification])

    meeting_id = params["meeting_id"]

    render(conn, "france-vae-redirect.html", %{
      container_class: "d-flex flex-grow-1",
      user_registration: Vae.Meetings.FranceVae.UserRegistration.from_application(application),
      form_url: Vae.Meetings.FranceVae.Config.get_france_vae_form_url(academy_id, meeting_id)
    })
  end

  def france_vae_registered(
        conn,
        %{
          "application_id" => id,
          "academy_id" => academy_id,
          "meeting_id" => meeting_id
        }
      ) do
    meeting = Vae.Meetings.get_by_meeting_id(meeting_id)

    render(conn, "france-vae-registered.html", %{
      container_class: "d-flex flex-grow-1",
      application_id: id,
      academy_id: academy_id,
      meeting: meeting
    })
  end
end
