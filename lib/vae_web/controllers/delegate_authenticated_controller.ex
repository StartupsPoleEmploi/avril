defmodule VaeWeb.DelegateAuthenticatedController do
  use VaeWeb, :controller

  alias Vae.{Certification, Delegate, UserApplication, User}

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
    render(conn, "edit.html", %{
      delegate: conn.assigns[:current_delegate]
    })
  end

  def update(conn, %{"id" => id} = params) do
    delegate = conn.assigns[:current_delegate]

    {level, msg} =
      case Delegate.changeset(delegate, params["delegate"]) |> Repo.update() do
        {:ok, _delegate} -> {:success, "Coordonnées enregistrées"}
        {:error, error} -> {:error, "Une erreur est survenue: #{inspect(error)}"}
      end
    conn
    |> put_flash(level, msg)
    |> redirect(to: Routes.delegate_authenticated_path(conn, :show, delegate))
  end

  def show(conn, _params) do
    delegates = User.delegates(Pow.Plug.current_user(conn))

    render(conn, "show.html", %{
      has_multiple_delegates: length(delegates) > 1,
      delegate: conn.assigns[:current_delegate]
    })
  end

  def certifications(conn, params) do
    %Delegate{certifications: certifications} = conn.assigns[:current_delegate]
    |> Repo.preload(:certifications)

    query = from(c in Certification, where: c.is_active)
      |> join(:inner, [c], d in assoc(c, :delegates))
      |> where([c, d], d.id == ^conn.assigns[:current_delegate].id)
      |> order_by([c, d], [c.acronym, c.label])

    page = Repo.paginate(query, Map.merge(params, %{page_size: 20}))

    render(conn, "certifications.html", %{
      delegate: conn.assigns[:current_delegate],
      certifications: page.entries,
      page: page
    })
  end

  def applications(conn, params) do

    query =
      from a in UserApplication,
      where: a.delegate_id == ^conn.assigns[:current_delegate].id and not is_nil(a.submitted_at),
      order_by: {:desc, a.submitted_at},
      preload: [:delegate, :certification, :user, :resumes]

    page = Repo.paginate(query, Map.merge(params, %{page_size: 20}))

    render(conn, "applications.html", %{
      delegate: conn.assigns[:current_delegate],
      applications: page.entries,
      page: page
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