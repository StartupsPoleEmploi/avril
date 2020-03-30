defmodule Vae.ExAdmin.Rome do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  register_resource Vae.Rome do
    index do
      selectable_column()
      column(:id)
      column(:code)
      column(:label)
      column(:url)

      actions()
    end

    show rome do
      attributes_table do
        row :id
        row(:category, fn r -> Vae.Rome.category(r) |> Helpers.link_to_resource() end)
        row(:subcategory, fn r -> Vae.Rome.subcategory(r) |> Helpers.link_to_resource() end)
        row :code
        row :label
        row :url
      end

      panel "Certifications" do
        table_for application.certifications do
          column(:label, fn r -> Helpers.link_to_resource(r) end)
        end
      end

      panel "Professions" do
        table_for application.professions do
          column(:label, fn r -> Helpers.link_to_resource(r, namify: fn p -> p.label end) end)
        end
      end
    end

    query do
      %{
        index: [default_sort: [asc: :id]],
        show: [preload: [:professions]]
      }
    end
  end
end
