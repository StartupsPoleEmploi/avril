defmodule Vae.ExAdmin.Application do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  # Note: Vae.Application cannot be aliased here: ex_admin fails
  alias Vae.{Certification, Delegate, Repo, User}

  require Ecto.Query

  register_resource Vae.Application do

    index do
      selectable_column()
      column(:id)
      column(:user, fn a -> User.fullname(a.user) end)
      column(:certification)
      column(:delegate)
      column(:certifier, fn a ->
        Enum.map(a.certifiers, &Helpers.link_to_resource/1)
      end)
      column(:administrative, fn a -> a.delegate && a.delegate.administrative end)
      column(:status, &application_status/1)
      column(:meeting)
      column(:booklet_1)

      actions()
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      href = Vae.Router.Helpers.application_path(Vae.Endpoint, :show, application,
        hash: application.delegate_access_hash
      )
      action_item_link "View Delegate Application", href: href, target: "_blank"
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      if !application.submitted_at do
        href = Vae.Router.Helpers.application_path(Vae.Endpoint, :update, application)
        action_item_link "Submit Application", href: href, "data-method": :put
      end
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      href = Vae.Router.Helpers.application_download_path(Vae.Endpoint, :download, application)
      action_item_link "Download Application Recap", href: href, download: "Synthese VAE.pdf"
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      if application.booklet_1 do
        action_item_link "Fill Booklet", href: Vae.Application.booklet_url(Vae.Endpoint, application), target: "_blank"
      end
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      if application.booklet_1 do
        action_item_link "Check CERFA", href: Vae.Application.booklet_url(Vae.Endpoint, application, "/cerfa"), target: "_blank"
      end
    end

    show application do
      attributes_table do
        row(:user, fn a -> User.fullname(a.user) end)
        row :certification
        row :delegate
        row :inserted_at
        row :submitted_at
        row :admissible_at
        row :inadmissible_at
        row :updated_at
        row(:meeting, fn a -> Helpers.print_in_json(a.meeting) end)
        row(:booklet_1, fn a -> Helpers.print_in_json(a.booklet_1) end)
        row :booklet_hash
      end

      panel "Resumes" do
        table_for Vae.Repo.preload(application, [:resumes]).resumes do
          column(:id, fn r -> Helpers.link_to_resource(r, namify: fn r -> r.id end) end)
          column(:file, fn r -> Phoenix.HTML.Link.link(r.filename, to: r.url) end)
          column(:inserted_at)
        end
      end
    end

    form application do
      inputs do
        input application, :user, collection: Repo.all(User)
        input application, :certification, collection: Repo.all(Certification)
        input application, :delegate, collection: Repo.all(Delegate)
        input application, :submitted_at
        input application, :meeting
      end
    end

    csv do
      column(:id)
      column(:user, fn a -> Helpers.csv_link_to_resource(a.user) end)
      column(:email, fn a -> a.user.email end)
      column(:certification, fn a -> Helpers.csv_link_to_resource(a.certification) end)
      column(:certifier, fn a ->
        Enum.join(Enum.map(a.certification.certifiers, fn c -> c.name end), ",")
      end)
      column(:delegate, fn a -> Helpers.csv_link_to_resource(a.delegate) end)
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

    filter [:meeting, :booklet_1, :booklet_hash]
    filter(:certification, order_by: [:acronym, :label])
    filter(:delegate, order_by: :name)
    filter [:id, :inserted_at, :updated_at, :submitted_at, :admissible_at, :inadmissible_at]

    query do
      %{
        all: [
          preload: [ :delegate, :user, :certification, :certifiers]
        ],
        index: [
          default_sort: [desc: :inserted_at]
        ]
      }
    end
  end

  defp application_status(application) do
    cond do
      application.admissible_at -> "Admissible le #{application.admissible_at |> Timex.format!("%d/%m/%Y", :strftime)}"
      application.inadmissible_at -> "Pas encore admissible au #{application.inadmissible_at |> Timex.format!("%d/%m/%Y", :strftime)}"
      application.submitted_at -> "Transmise le #{application.submitted_at |> Timex.format!("%d/%m/%Y", :strftime)}"
      true -> nil
    end
  end
end
