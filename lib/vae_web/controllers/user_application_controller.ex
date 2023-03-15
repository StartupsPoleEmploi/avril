defmodule VaeWeb.UserApplicationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{Certification, Delegate, Identity, User, UserApplication, Repo}
  alias Vae.Booklet.{Cerfa, Education, CurrentSituation}
  plug VaeWeb.Plugs.ApplicationAccess,
       [verify_with_hash: :delegate_access_hash] when action in [:show, :cerfa]

  def show(conn, %{"hash" => hash}) when not is_nil(hash) do
    redirect(conn,
      to:
        Routes.user_application_path(conn, :show, conn.assigns[:current_application],
          delegate_hash: conn.assigns[:current_application].delegate_access_hash
        )
    )
  end

  def show(conn, _params) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([
        :user,
        [delegate: [:certifiers]],
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
        "Candidature VAE de #{User.fullname(application.user)} pour un diplôme de #{
          Certification.name(application.certification)
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

  def cerfa(conn, params) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([
        :user,
        [delegate: [:certifiers]],
        :certification,
        :resumes
      ])
    title = "Recevabilité VAE de #{User.fullname(application.user)} pour un diplôme de #{
      Certification.name(application.certification)
    }"
    assigns = %{
      conn: conn,
      title: title,
      remove_navbar: true,
      remove_footer: true,
      is_delegate_view: not is_nil(params["delegate_hash"]),
      application: application,
      certification_level: application.certification.level,
      certification_name: Certification.name(application.certification),
      certifier_name: UserApplication.certifier_name(application),
      identity: Vae.Maybe.try(application, [:user, :identity], %Identity{}),
      current_situation: Vae.Maybe.try(application, [:user, :identity, :current_situation], %CurrentSituation{}),
      booklet: Vae.Maybe.try(application, :booklet_1, %Cerfa{}),
      education: Vae.Maybe.try(application, [:booklet_1, :education], %Education{}),
      experiences: Vae.Maybe.try(application, [:booklet_1, :experiences], [])
        |> Enum.reject(&(&1.periods == []))
        |> Enum.sort_by(fn e ->
          Enum.max_by(e.periods, &Date.to_erl(&1.start_date), fn -> Date.utc_today() end)
        end)
    }

    if params["format"] == "pdf" do
      file_path = Phoenix.View.render_to_string(VaeWeb.UserApplicationView, "cerfa.html", Map.merge(assigns, %{
        conn: conn,
        layout: {VaeWeb.LayoutView, "pdf.html"},
      }))
      |> PdfGenerator.generate!(shell_params: ["--encoding", "UTF8"])

      conn
      |> put_resp_content_type("application/pdf")
      |> put_resp_header("content-disposition", "attachment; filename=#{Vae.String.parameterize(title, " ")}.pdf")
      |> Plug.Conn.send_file(:ok, file_path)
    else
      render(conn, "cerfa.html", assigns)
    end
  end

  def admissible(conn, %{"id" => id}) do
    user_application_admissibility_status(conn, true, id)
  end

  def inadmissible(conn, %{"id" => id}) do
    user_application_admissibility_status(conn, false, id)
  end

  defp user_application_admissibility_status(conn, is_admissible, id) do
    Repo.get(UserApplication, id)
    |> case do
      nil ->
        conn
        |> Phoenix.Controller.put_flash(:warning, "La candidature n'a pas été trouvée")
        |> Phoenix.Controller.redirect(conn, to: Routes.root_path(conn, :index))

      application ->
        if is_admissible do
          UserApplication.admissible_now(application)
        else
          UserApplication.inadmissible_now(application)
        end

        conn
        |> Phoenix.Controller.put_flash(:success, "Merci pour votre réponse")
        |> Phoenix.Controller.redirect(to: Routes.root_path(conn, :index))
    end

  end
end
