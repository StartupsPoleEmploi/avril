defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.{Application, Delegate, Resume, User}
  alias Vae.Delegates.Client.FranceVae
  alias Vae.Crm.Polls

  def show(conn, %{"id" => id} = params) do
    application =
      case Repo.get(Application, id) do
        nil ->
          nil

        application ->
          Repo.preload(application, [:user, [delegate: :process], :certification, :resumes])
      end

    case has_access?(conn, application, params["hash"]) do
      {:ok, application} ->
        render(conn, "show.html",
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
          external_subscription_link: Delegate.external_subscription_link(application.delegate),
          user_changeset: User.changeset(application.user, %{}),
          resume_changeset: Resume.changeset(%Resume{}, %{}),
          meetings:
            Vae.Delegate.is_educ_nat?(application.delegate) &&
              Vae.Delegates.get_france_vae_meetings(application.delegate.academy_id)
        )

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  # TODO: change to submit
  def update(conn, %{"id" => id}) do
    application =
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user, :delegate, :certification])
      end

    case has_access?(conn, application, nil) do
      {:ok, application} ->
        case Application.submit(application) do
          {:ok, application} ->
            conn
            |> put_flash(:success, "Dossier transmis avec succès!")
            |> redirect(to: Routes.application_path(conn, :show, application))

          {:error, msg} ->
            conn
            |> put_flash(
              :error,
              "Une erreur est survenue: \"#{msg}\". N'hésitez pas à nous contacter pour plus d'infos."
            )
            |> redirect(to: Routes.application_path(conn, :show, application))
        end

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  def download(conn, %{"application_id" => id}) do
    application =
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user, {:delegate, :process}, :certification])
      end

    case has_access?(conn, application, nil) do
      {:ok, application} ->
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

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
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
        |> redirect(external: url_form)
    end
  end

  def register_to_meeting(conn, %{
        "academy_id" => academy_id,
        "meeting_id" => meeting_id,
        "id" => id
      }) do
    application =
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user, {:delegate, :process}, :certification])
      end

    case has_access?(conn, application, nil) do
      {:ok, application} ->
        case Vae.Delegates.Api.post_meeting_registration(academy_id, meeting_id, application.user) do
          :ok ->
            Application.set_registered_meeting(application, academy_id, meeting_id)

          {:error, message} ->
            Logger.error(fn -> inspect(message) end)

            conn
            |> put_flash(:error, "Une erreur est survenue")
            |> redirect(to: Routes.application_path(conn, :show, application))
        end

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  def has_access?(conn, application, nil) do
    if not is_nil(application) do
      if Coherence.logged_in?(conn) &&
           (Coherence.current_user(conn).id == application.user.id ||
              Coherence.current_user(conn).is_admin) do
        {:ok, application}
      else
        {:error,
         %{
           to: Routes.session_path(conn, :new, %{"mode" => "pe-connect"}),
           msg: "Vous devez vous connecter"
         }}
      end
    else
      {:error, %{to: Routes.root_path(conn, :index), msg: "Vous n'avez pas accès."}}
    end
  end

  def has_access?(conn, application, hash) do
    # && Timex.before?(Timex.today, Timex.shift(application.delegate_access_refreshed_at, days: 10))
    if not is_nil(application) &&
         application.delegate_access_hash == hash do
      {:ok, application}
    else
      {:error,
       %{
         to: Routes.root_path(conn, :index),
         msg:
           if(application.delegate_access_hash == hash,
             do: "Accès expiré",
             else: "Vous n'avez pas accès"
           )
       }}
    end
  end
end
