defmodule VaeWeb.Schema.CertificationTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers.Authorities

  object :certification do
    field(:id, :id)
    field(:slug, :string)
    field(:acronym, :string)
    field(:label, :string)
    field(:level, :string)
    field(:certifiers, list_of(:certifier)) do
      resolve(&Authorities.certifiers_list/3)
    end
  end
end
