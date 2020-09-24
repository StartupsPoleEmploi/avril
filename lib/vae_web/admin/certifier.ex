defmodule Vae.ExAdmin.Certifier do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  register_resource Vae.Certifier do

    index do
      column(:id)
      column(:name)
      column(:active_certifications, fn a -> length(a.certifications) end)
      column(:active_delegates, fn a -> length(a.delegates) end)
      actions()
    end

    show certifier do
      attributes_table

      panel Vae.String.inflect(length(certifier.certifications), "active certification", [lang: :en]) do
        table_for certifier.certifications do
          column(:id)
          column(:rncp_id)
          column(:name, fn a -> Helpers.link_to_resource(a) end)
          column(:is_active)
        end
      end

      panel Vae.String.inflect(length(certifier.delegates), "active delegate", [lang: :en]) do
        table_for certifier.delegates do
          column(:id)
          column(:name, fn a -> Helpers.link_to_resource(a) end)
          column(:city)
          column(:administrative)
          column(:is_active)
        end
      end
    end


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
