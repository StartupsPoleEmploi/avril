defmodule Vae.ExAdmin.Rome do
  use ExAdmin.Register

  register_resource Vae.Rome do
    index do
      selectable_column()
      column(:id)
      column(:code)
      column(:label)
      column(:url)

      actions()
    end

    query do
      %{
        index: [default_sort: [asc: :id]]
      }
    end
  end
end
