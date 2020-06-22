defmodule VaeWeb.UserApplicationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{UserApplications.Polls, Delegate, User, UserApplication, Repo}

  plug VaeWeb.Plugs.ApplicationAccess,
       [verify_with_hash: :delegate_access_hash] when action in [:show]

  def index(conn, params) do
    with(
      current_user when not is_nil(current_user) <-
        Pow.Plug.current_user(conn),
      current_application when not is_nil(current_application) <-
        Repo.preload(current_user, :applications).applications
        |> Enum.find(fn a -> a.booklet_hash == params["hash"] end)
    ) do
      case params["msg"] do
        "request_failed" ->
          put_flash(
            conn,
            :danger,
            "Nous n'avons pas réussi à récupérer vos données. Merci de réessayer plus tard."
          )

        "not_allowed" ->
          put_flash(conn, :danger, "Vous n'avez pas accès.")

        _ ->
          conn
      end
      |> redirect(external: User.profile_url(conn, current_application))
    else
      _error ->
        conn
        |> put_flash(:danger, "Vous n'avez pas accès")
        |> redirect(to: Routes.root_path(conn, :index))
    end
  end

  def show(conn, %{"hash" => hash}) when not is_nil(hash) do
    redirect(conn, to: Routes.user_application_path(conn, :show, conn.assigns[:current_application], delegate_hash: conn.assigns[:current_application].delegate_access_hash))
  end
  def show(conn, %{"delegate_hash" => hash}) when not is_nil(hash) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([
        :user,
        [delegate: [:process, :certifiers]],
        :certification,
        :resumes
      ])

    grouped_experiences =
      application.user.proven_experiences
      |> Enum.group_by(fn exp -> {exp.company_name, exp.label} end)
      |> Vae.Map.map_values(fn {_k, experiences} ->
        Enum.sort_by(experiences, fn exp -> Date.to_erl(exp.start_date) end, &>/2)
      end)
      |> Map.to_list()
      |> Enum.sort_by(fn {_k, v} -> Date.to_erl(List.first(v).start_date) end, &>/2)

    render(conn, "show.html", %{
      title:
        "Candidature VAE de #{application.user.name} pour un diplôme de #{
          application.certification.label
        }",
      remove_navbar: true,
      application: application,
      delegate: application.delegate,
      delegate_changeset: Delegate.changeset(application.delegate, %{}),
      certification: application.certification,
      user: application.user,
      grouped_experiences: grouped_experiences
    })
  end

  def show(conn, _params) do
    if Pow.Plug.current_user(conn) == conn.assigns[:current_application].user do
      redirect(conn, external: Vae.User.profile_url(conn, conn.assigns[:current_application]))
    else
      redirect(conn, external: Vae.User.profile_url(conn))
    end
  end

  # TODO: change to submit
  # def update(conn, %{"id" => _id} = params) do
  #   application =
  #     conn.assigns[:current_application]
  #     |> Repo.preload([
  #       :user,
  #       [delegate: [:process, :certifiers]],
  #       :certification
  #     ])

  #   meeting_id =
  #     if params["book"] == "on",
  #       do: params["application"]["meeting_id"]

  #   with(
  #     {:ok, application} <- UserApplication.register_meeting(application, meeting_id),
  #     {:ok, application} <- UserApplication.submit(application)
  #   ) do
  #     if application.meeting && application.meeting.name == :france_vae do
  #       redirect(conn,
  #         to:
  #           Routes.user_application_france_vae_registered_path(
  #             conn,
  #             :france_vae_registered,
  #             application,
  #             %{
  #               academy_id: application.delegate.academy_id,
  #               meeting_id: application.meeting.meeting_id
  #             }
  #           )
  #       )
  #     else
  #       conn
  #       |> put_flash(:succes, "Votre profil a été transmis avec succès !")
  #       |> redirect(to: Routes.user_application_path(conn, :show, application))
  #     end
  #   else
  #     {:error, msg} ->
  #       Logger.error(fn -> inspect(msg) end)

  #       conn
  #       |> put_flash(:danger, "Une erreur est survenue, merci de réessayer plus tard")
  #       |> redirect(to: Routes.user_application_path(conn, :show, application))
  #   end
  # end

  # def download(conn, %{"application_id" => _id}) do
  #   application =
  #     conn.assigns[:current_application]
  #     |> Repo.preload([
  #       :user,
  #       [delegate: [:process, :certifiers]],
  #       :certification
  #     ])

  #   case Vae.StepsPdf.create_pdf_file(application.delegate.process) do
  #     {:ok, file} ->
  #       conn
  #       |> put_resp_content_type("application/pdf", "utf-8")
  #       |> send_file(200, file)

  #     {:error, msg} ->
  #       conn
  #       |> put_flash(:danger, "Une erreur est survenue: #{msg}. Merci de réessayer plus tard.")
  #       |> redirect(to: Routes.user_application_path(conn, :show, application))
  #   end
  # end

  def admissible(conn, %{"id" => id}) do
    Repo.get(UserApplication, id)
    |> case do
      nil ->
        redirect(conn, to: Routes.root_path(conn, :index))

      application ->
        UserApplication.admissible_now(application)

        conn
        |> put_flash(:success, "Merci pour votre réponse")
        |> redirect(to: Routes.root_path(conn, :index))
    end
  end

  def inadmissible(conn, %{"id" => id}) do
    Repo.get(UserApplication, id)
    |> Repo.preload(delegate: :certifiers)
    |> case do
      nil ->
        redirect(conn, to: Routes.root_path(conn, :index))

      application ->
        UserApplication.inadmissible_now(application)

        url_form = Polls.define_form_url_from_application(application)

        conn
        |> redirect(external: url_form || Routes.root_path(conn, :index))
    end
  end
end
