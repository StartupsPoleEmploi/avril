defmodule VaeWeb.Schema.Types.Profession do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers.Authorities

  object :profession do
    field(:id, :id)
    field(:label, :string)
  end
end
