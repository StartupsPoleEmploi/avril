defmodule VaeWeb.Schema.Types.Profession do
  use Absinthe.Schema.Notation

  object :profession do
    field(:id, :id)
    field(:label, :string)
  end
end
