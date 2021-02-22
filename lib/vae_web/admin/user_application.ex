defmodule Vae.ExAdmin.UserApplication do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  # Note: Vae.UserApplication cannot be aliased here: ex_admin fails
  alias Vae.{Certification, Delegate, Repo}

  require Ecto.Query

  register_resource Vae.UserApplication do
    action_items except: [:new, :create, :delete]

    index do
      selectable_column()
      column(:id)
      column(:user, fn a -> Vae.User.fullname(a.user) end)
      column(:certification)
      column(:delegate)

      # column(:certifiers, fn d ->
      #   Enum.map(d.certifiers, &Helpers.link_to_resource(&1)) |> Enum.intersperse(", ")
      # end)
      column(:administrative, fn a -> a.delegate && a.delegate.administrative end)
      column(:status, &application_status/1)
      column(:delegate_application_url, fn a -> if a.submitted_at, do: Phoenix.HTML.Link.link("URL", to: VaeWeb.Router.Helpers.user_application_url(VaeWeb.Endpoint, :show, a, delegate_hash: a.delegate_access_hash), target: "_blank") end)
      column(:meeting_subscription, fn a -> if a.meeting, do: "Yes", else: "No" end)
      column(:booklet_1)

      actions()
    end

    action_item(:show, fn id ->
      application = Vae.Repo.get(Vae.UserApplication, id)

      if application.delegate_access_hash && application.booklet_1 do
        action_item_link("View CERFA",
          href: VaeWeb.Router.Helpers.user_application_path(VaeWeb.Endpoint, :cerfa, application, delegate_hash: application.delegate_access_hash),
          target: "_blank"
        )
      end
    end)

    action_item(:show, fn id ->
      application = Vae.Repo.get(Vae.UserApplication, id)

      href =
        VaeWeb.Router.Helpers.user_application_path(VaeWeb.Endpoint, :show, application,
          delegate_hash: application.delegate_access_hash
        )

      if application.delegate_access_hash do
        action_item_link("View Delegate Application", href: href, target: "_blank", class: "strong")
      end
    end)

    show application do
      attributes_table() do
        row(:user, fn a -> Vae.User.fullname(a.user) end)
        row(:certification)
        row(:delegate)
        row(:delegate_application_url, fn a -> if a.submitted_at, do: Phoenix.HTML.Link.link("Click to visit or right click \"Save link as ...\"", to: VaeWeb.Router.Helpers.user_application_url(VaeWeb.Endpoint, :show, a, delegate_hash: a.delegate_access_hash), target: "_blank") end)
        row(:inserted_at)
        row(:submitted_at)
        row(:admissible_at)
        row(:inadmissible_at)
        row(:updated_at)
        row(:meeting_infos, fn a -> Helpers.print_in_json(a.meeting) end)
        row(:booklet_1, fn a -> Helpers.print_in_json(a.booklet_1) end)
        row(:booklet_hash)
      end

      panel "Resumes" do
        table_for application.resumes do
          column(:id, fn r -> Helpers.link_to_resource(r, namify: fn r -> r.id end) end)
          column(:file, fn r -> Phoenix.HTML.Link.link(r.filename, to: r.url) end)
          column(:inserted_at)
        end
      end
    end

    member_action :delete,
      &__MODULE__.delete_user_application/2,
      label: "Delete User Application",
      icon: "minus-square"

    def delete_user_application(conn, %{id: id}) do
      ua = Vae.Repo.get(Vae.UserApplication, id)

      case Vae.UserApplication.delete_with_resumes(ua) do
        {:ok, _} ->
          conn
          |> Phoenix.Controller.put_flash(:notice, "Candidature supprimée")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(UserApplication))
        _ ->
          conn
          |> Phoenix.Controller.put_flash(:danger, "La candidature n'a pas été supprimée.")
          |> Phoenix.Controller.redirect(to: ExAdmin.Utils.admin_resource_path(ua))
      end
    end

    form application do
      inputs do
        application = Repo.preload(application, :user)
        if application.user do
          input(application, :user, collection: [application.user])
        end
        input(application, :certification, collection: Repo.all(Certification, order_by: [asc: :id]))
        input(application, :delegate, collection: Repo.all(from(d in Delegate, order_by: [asc: d.name])))
        input(application, :submitted_at)
        input(application, :meeting)
      end
    end

    csv do
      column(:id)
      column(:url, fn a -> if a.submitted_at, do: VaeWeb.Router.Helpers.user_application_url(VaeWeb.Endpoint, :show, a, delegate_hash: a.delegate_access_hash) end)
      column(:user@first_name, fn a -> a.user.first_name end)
      column(:user@last_name, fn a -> a.user.last_name end)
      # column(:user, fn a -> Helpers.csv_link_to_resource(a.user) end)
      column(:email, fn a -> a.user.email end)
      column(:certification, fn a -> Certification.name(a.certification) end)
      # column(:certification, fn a -> Helpers.csv_link_to_resource(a.certification) end)

      column(:certifier, fn a ->
        Enum.join(Enum.map(a.certification.certifiers, fn c -> c.name end), ",")
      end)

      column(:delegate, fn a -> a.delegate && a.delegate.name end)
      # column(:delegate, fn a -> Helpers.csv_link_to_resource(a.delegate) end)
      column(:administrative, fn a -> a.delegate && a.delegate.administrative end)
      column(:inserted_at)
      column(:submitted_at)
      column(:admissible_at)
      column(:inadmissible_at)
      column(:updated_at)
      column(:meeting)
      column(:booklet_1)
      column(:booklet_1@inserted_at, fn a -> a.booklet_1 && a.booklet_1.inserted_at end)
      column(:booklet_1@completed_at, fn a -> a.booklet_1 && a.booklet_1.completed_at end)
    end

    filter([:booklet_1, :booklet_hash])
    filter(:meeting, type: :present_only)
    filter(:delegate, type: :hidden)
    filter(:certification, type: :hidden)
    filter(:user, type: :hidden)
    filter([:id, :inserted_at, :updated_at, :submitted_at, :admissible_at, :inadmissible_at])

    @all_preloads [:delegate, :user, :certification, :certifiers, :meeting]

    query do
      %{
        index: [
          default_sort: [desc: :inserted_at]
        ],
        show: [
          preload: @all_preloads ++ [:resumes]
        ],
        all: [
          preload: @all_preloads
        ]
      }
    end
  end

  defp application_status(application) do
    cond do
      application.admissible_at ->
        "Admissible le #{application.admissible_at |> Timex.format!("%d/%m/%Y", :strftime)}"

      application.inadmissible_at ->
        "Pas encore admissible au #{
          application.inadmissible_at |> Timex.format!("%d/%m/%Y", :strftime)
        }"

      application.submitted_at ->
        "Transmise le #{application.submitted_at |> Timex.format!("%d/%m/%Y", :strftime)}"

      true ->
        nil
    end
  end
end
