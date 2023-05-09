defmodule Vae.ExAdmin.Certifier do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  register_resource Vae.Certifier do

    index do
      column(:id)
      column(:name)
      column(:rncp_sync)
      column(:siret)
      column(:active_certifications, fn a -> Enum.count(a.certifications, &(&1.is_active)) end)
      column(:active_delegates, fn a -> Enum.count(a.delegates, &(&1.is_active)) end)
      actions()
    end

    show certifier do
      attributes_table()

      panel "certifications" do
        table_for certifier.certifications do
          column(:id)
          column(:rncp_id)
          column(:name, fn a -> Helpers.link_to_resource(a) end)
          column(:is_active)
        end
      end

      panel "delegates" do
        table_for certifier.delegates do
          column(:id)
          column(:name, fn a -> Helpers.link_to_resource(a) end)
          column(:city)
          column(:administrative)
          column(:is_active)
        end
      end
    end

    form certifier do
      inputs do
        input(certifier, :name)
        input(certifier, :rncp_sync)
        input(certifier, :siret)
        input(certifier, :external_notes, type: :text, placeholder: "Extra infos for the candidate")
        input(certifier, :internal_notes, type: :text, placeholder: "Internal Avril notes")
      end
    end

    filter(:delegates, scope: :active)
    filter(:certifications, scope: :active)
    filter([:id, :slug, :name, :rncp_sync, :siret, :internal_notes, :inserted_at, :updated_at])

    query do
      %{
        index: [default_sort: [asc: :id]],
        all: [
          preload: [
            :certifications,
            :delegates,
          ]
        ]
      }
    end

  end
end
