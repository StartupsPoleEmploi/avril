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
      column(:user)
      column(:certification)
      column(:delegate)
      column(:certifier, fn a ->
        Enum.map(a.certifiers, &Helpers.link_to_resource/1)
      end)
      column(:administrative, fn a -> a.delegate.administrative end)
      column(:submitted_at)
      column(:admissible_at)
      column(:inadmissible_at)

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
      href = Vae.Router.Helpers.application_path(Vae.Endpoint, :update, application)
      action_item_link "Submit Application", href: href, "data-method": :put
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      href = Vae.Router.Helpers.application_download_path(Vae.Endpoint, :download, application)
      action_item_link "Download Application Recap", href: href, download: "Synthese VAE.pdf"
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae. Application, id)
      action_item_link "Fill Booklet", href: Vae.Application.booklet_url(application), target: "_blank"
    end

    show application do
      attributes_table do
        row :user
        row :certification
        row :delegate
        row :submitted_at
        row :meeting
        row :admissible_at
        row :inadmissible_at
        row :inserted_at
        row :updated_at
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
      column(:user, fn a -> User.fullname(a.user) end)
      column(:email, fn a -> a.user.email end)
      column(:certification, fn a -> Certification.name(a.certification) end)
      column(:certifier, fn a ->
        Enum.join(Enum.map(a.certification.certifiers, fn c -> c.name end), ",")
      end)
      column(:delegate, fn a -> a.delegate && a.delegate.name end)
      column(:administrative, fn a -> a.delegate && a.delegate.administrative end)
      column(:submitted_at)
      column(:admissible_at)
      column(:inadmissible_at)
      column(:inserted_at)
      column(:updated_at)
    end

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
        # show: [
        #   preload: [:resumes]
        # ]
      }
    end
  end
end
