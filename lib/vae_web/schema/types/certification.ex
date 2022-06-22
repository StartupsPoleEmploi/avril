defmodule VaeWeb.Schema.Types.Certification do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers.Authorities

  object :certification do
    field(:id, :id)
    field(:is_active, :boolean)
    field(:slug, :string)
    field(:acronym, :string)
    field(:label, :string)
    field(:level, :string)
    field(:external_notes, :string)
    field(:certifiers, list_of(:certifier)) do
      resolve(&Authorities.certifiers_list/3)
    end
  end
end
