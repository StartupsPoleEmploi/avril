defmodule Vae.ExAdmin.Certifier do
  use ExAdmin.Register

  register_resource Vae.Certifier do
    query do
      %{
        index: [default_sort: [asc: :id]]
      }
    end

  end
end
