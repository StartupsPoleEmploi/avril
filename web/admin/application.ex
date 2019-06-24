defmodule Vae.ExAdmin.Application do
  use ExAdmin.Register
  alias Vae.Repo.NewRelic, as: Repo

  alias Vae.User
  alias Vae.Certification
  alias Vae.Delegate

  require Ecto.Query

  register_resource Vae.Application do

    index do
      selectable_column()
      column(:id)
      column(:user)
      column(:certification)
      column(:certifier, fn a ->
        Enum.map(a.certification.certifiers, fn c ->
          Phoenix.HTML.Link.link(c.name, to: "/admin/certifiers/#{c.id}")
        end)
      end)
      column(:delegate)
      column(:administrative, [], fn a -> a.delegate.administrative end)
      column(:submitted_at)
      column(:admissible_at)
      column(:inadmissible_at)

      actions()
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae.Application, id)
      href = Vae.Router.Helpers.application_path(Vae.Endpoint, :show, application,
        hash: application.delegate_access_hash
      )
      action_item_link "View Delegate Application", href: href, target: "_blank"
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae.Application, id)
      href = Vae.Router.Helpers.application_path(Vae.Endpoint, :update, application)
      action_item_link "Submit Application", href: href, "data-method": :put
    end

    action_item :show, fn id ->
      application = Vae.Repo.get(Vae.Application, id)
      href = Vae.Router.Helpers.application_download_path(Vae.Endpoint, :download, application)
      action_item_link "Download Application Recap", href: href, download: "Synthese VAE.pdf"
    end

    show _application do
      attributes_table do
        row :user
        row :certification
        row :delegate
        row :submitted_at
        row :admissible_at
      end
    end

    form application do
      inputs do
        input application, :user, collection: Repo.all(User)
        input application, :certification, collection: Repo.all(Certification)
        input application, :delegate, collection: Repo.all(Delegate)
      end
    end

    csv do
      column(:id)
      column(:user, fn a -> a.user.name end)
      column(:certification, fn a -> Certification.name(a.certification) end)
      column(:certifier, fn a ->
        Enum.join(Enum.map(a.certification.certifiers, fn c -> c.name end), ",")
      end)
      column(:delegate, fn a -> a.delegate.name end)
      column(:administrative, fn a -> a.delegate.administrative end)
      column(:submitted_at)
      column(:admissible_at)
      column(:inserted_at)
      column(:updated_at)
    end

    filter [:id, :submitted_at, :admissible_at, :inserted_at, :updated_at]

    query do
      %{
        all: [
          preload: [ :delegate, :user, certification: :certifiers]
        ],
        index: [
          default_sort: [asc: :inserted_at]
        ]
      }
    end
  end
end
