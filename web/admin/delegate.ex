defmodule Vae.ExAdmin.Delegate do
  use ExAdmin.Register
  alias Vae.Repo.NewRelic, as: Repo
  alias Vae.Certifier
  alias Vae.Process

  alias Ecto.Query
  require Ecto.Query

  register_resource Vae.Delegate do
    update_changeset(:changeset_update)
    create_changeset(:changeset_update)

    index do
      selectable_column()
      column(:id)
      column(:name)
      column(:process)
      column(:is_active)
      column(:administrative)
      column(:city)

      actions()
    end

    show delegate do
      attributes_table(
        only: [
          :id,
          :is_active,
          :name,
          :website,
          :address,
          :telephone,
          :email,
          :person_name,
          :certifier,
          :process
        ]
      )
    end

    form delegate do
      inputs do
        input(delegate, :is_active)
        input(delegate, :name)
        input(delegate, :website)
        input(delegate, :address)
        input(delegate, :geo, type: :hidden)
        input(delegate, :telephone)
        input(delegate, :email)
        input(delegate, :person_name)
        input(delegate, :certifier, collection: certifiers())
        input(delegate, :process, collection: processes())
      end
    end
  end

  defp certifiers() do
    Certifier |> Query.order_by(:name) |> Repo.all()
  end

  defp processes() do
    Process |> Query.order_by(:name) |> Repo.all()
  end
end
