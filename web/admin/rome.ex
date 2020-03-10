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

      panel "Professions" do
        table_for rome.professions do
          column(:id, fn p -> Helpers.link_to_resource(p, namify: fn p -> p.id end) end)
          column(:label)
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
