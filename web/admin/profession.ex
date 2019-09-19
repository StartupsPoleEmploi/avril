defmodule Vae.ExAdmin.Profession do
  use ExAdmin.Register

  register_resource Vae.Profession do
    query do
      %{
        index: [default_sort: [asc: :id]]
      }
    end
  end
end
