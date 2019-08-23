defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.{Application, Resume, User}
  alias Vae.Crm.Polls

  plug Vae.Plugs.ApplicationAccess

  def show(conn, %{"id" => id} = params) do
    application =
      case Repo.get(Application, id) do
        nil ->
          nil

        application ->
          Repo.preload(application, [:user, [delegate: :process], :certification, :resumes])
      end

    meetings =
      if application.meeting,
        do: [],
        else:
          Vae.Delegates.get_france_vae_meetings(application.delegate.academy_id)
          |> Enum.group_by(fn meeting -> {meeting.place, meeting.address} end)
          |> Map.to_list()
          |> Enum.map(fn {{place, _address}, _meetings} ->
            {{place, _address, Vae.String.parameterize(place)}, _meetings}
          end)

    preselected_place =
      Enum.find(meetings, {nil, []}, fn {{place, _address, _slug}, _meetings} ->
        place |> String.split(",") |> List.last() |> String.trim() ==
          application.delegate.city
      end)
      |> (fn {infos, _m} -> infos end).()

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
        |> Vae.Map.map_values(fn experiences ->
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
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user, :delegate, :certification])
      end

    case Application.submit(application) do
      {:ok, application} ->
        if application.delegate.academy_id do
          meeting_id = if params["book"] == "on", do: params["application"]["meeting_id"]

          with {:ok, _response} <-
                 Vae.Delegates.register_to_france_vae_meeting(
                   application.delegate.academy_id,
                   meeting_id,
                   application
                 ),
               {:ok, application} <-
                 Application.set_registered_meeting(
                   application,
                   application.delegate.academy_id,
                   meeting_id
                 ) do
            conn
            |> redirect(
              to:
                Routes.application_france_vae_registered_path(
                  conn,
                  :france_vae_registered,
                  application,
                  %{academy_id: application.delegate.academy_id}
                  |> Map.merge(if meeting_id, do: %{meeting_id: meeting_id}, else: %{})
                )
            )
          else
            msg ->
              conn
              |> put_flash(:error, msg)
              |> redirect(to: Routes.application_path(conn, :show, application))
          end
        else
          conn
          |> put_flash(:success, "Dossier transmis avec succès!")
          |> redirect(to: Routes.application_path(conn, :show, application))
        end

      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: Routes.application_path(conn, :show, application))
    end
  end

  def download(conn, %{"application_id" => id}) do
    application =
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user, {:delegate, :process}, :certification])
      end

    case Vae.StepsPdf.create_pdf_file(application.delegate.process) do
      {:ok, file} ->
        conn
        |> put_resp_content_type("application/pdf", "utf-8")
        |> send_file(200, file)

      {:error, msg} ->
        conn
        |> put_flash(:error, "Une erreur est survenue: #{msg}. Merci de reéssayer plus tard.")
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
          "application_id" => id,
          "academy_id" => academy_id
        } = params
      ) do
    application =
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user, {:delegate, :process}, :certification])
      end

    meeting_id = params["meeting_id"]

    render(conn, "france-vae-redirect.html", %{
      container_class: "d-flex flex-grow-1",
      user_registration: Vae.Delegates.FranceVae.UserRegistration.from_application(application),
      form_url: Vae.Delegates.FranceVae.Config.get_france_vae_form_url(academy_id, meeting_id)
    })
  end

  def france_vae_registered(
        conn,
        %{
          "application_id" => id
        }
      ) do
    render(conn, "france-vae-registered.html", %{
      container_class: "d-flex flex-grow-1",
      application_id: id
    })
  end
end
