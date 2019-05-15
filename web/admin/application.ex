defmodule Vae.ExAdmin.Application do
  use ExAdmin.Register
  alias Vae.Repo.NewRelic, as: Repo

  alias Vae.User
  alias Vae.Certification
  alias Vae.Delegate

  alias Ecto.Query
  require Ecto.Query

  register_resource Vae.Application do

    index do
      selectable_column()
      column(:id)
      column(:user)
      column(:certification)
      column(:delegate)
      column(:submitted_at)
      column(:admissible_at)

      actions()
    end

    show application do
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

    member_action :submit_application, &__MODULE__.submit_application/2


    query do
      %{
        all: [
          preload: [ :delegate, :user, :certification]
        ]
      }
    end
  end

  def submit_application(conn, params) do
    application = Repo.get(Application, params[:id])
    Application.submit(application)
    Controller.redirect(to: ExAdmin.Utils.admin_application_path(conn, :show, params[:id]))
  end
end
