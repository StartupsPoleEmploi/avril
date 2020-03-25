defmodule VaeWeb.Schema.CertificationTypes do
  use Absinthe.Schema.Notation

  object :certification do
    field(:id, :id)
    field(:slug, :string)
    field(:acronym, :string)
    field(:label, :string)
    field(:level, :string)
  end
end
