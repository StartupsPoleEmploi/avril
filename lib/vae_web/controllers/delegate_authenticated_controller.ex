defmodule VaeWeb.DelegateAuthenticatedController do
  use VaeWeb, :controller

  alias Vae.{Delegate, UserApplication, User}

  plug :check_delegate_access when action not in [:index]

  def index(conn, _params) do
    delegates = User.delegates(Pow.Plug.current_user(conn))
    case delegates do
      [] -> conn
        |> put_flash(:danger, "Aucun certificateur n'est associé à votre compte. Merci de nous contacter pour avoir plus d'informations à ce sujet.")
        |> redirect(to: Routes.root_path(:index))
      [%Delegate{} = delegate] ->
        redirect(conn, to: Routes.delegate_authenticated_path(conn, :show, delegate))
      _ ->
        render(conn, "index.html", %{
          delegates: User.delegates(Pow.Plug.current_user(conn))
        })
    end
  end

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def show(conn, _params) do
    delegates = User.delegates(Pow.Plug.current_user(conn))

    render(conn, "show.html", %{
      has_multiple_delegates: length(delegates) > 1,
      delegate: conn.assigns[:current_delegate]
    })
  end

  def certifications(conn, _params) do
    %Delegate{certifications: certifications} = conn.assigns[:current_delegate]
    |> Repo.preload(:certifications)

    render(conn, "certifications.html", %{
      delegate: conn.assigns[:current_delegate],
      certifications: certifications
    })
  end

  def applications(conn, _params) do

    applications = Repo.all(
      from a in UserApplication,
      where: a.delegate_id == ^conn.assigns[:current_delegate].id and not is_nil(a.submitted_at),
      order_by: {:desc, a.inserted_at},
      preload: [:delegate, :certification, :user]
    )

    render(conn, "applications.html", %{
      delegate: conn.assigns[:current_delegate],
      applications: applications
    })
  end

  defp check_delegate_access(%{params: params} = conn, _opts) do
    delegate_id = params["delegate_authenticated_id"] || params["id"]
    if delegate = Enum.find(User.delegates(Pow.Plug.current_user(conn)), &(&1.id == Vae.String.to_id(delegate_id))) do
      Plug.Conn.assign(conn, :current_delegate, delegate)
    else
      conn
      |> put_flash(:danger, "Vous n'avez pas accès")
      |> redirect(to: Routes.root_path(conn, :index))
    end
  end
end