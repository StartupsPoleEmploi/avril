defmodule Vae.ExAdmin.Profession do
  use ExAdmin.Register
  alias Vae.ExAdmin.Helpers

  register_resource Vae.Profession do
    query do
      %{
        all: [preload: [:rome]],
        index: [
          default_sort: [asc: :id]
        ]
      }
    end
  end
end
