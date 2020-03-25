defmodule VaeWeb.Schema.AuthoritiesTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :authorities_queries do
    @desc "Returns the list of delegates from the closest to the furthest from the postal code of the user and the application ID"
    field(:delegate_search, list_of(:delegate)) do
      arg(:application_id, non_null(:id))
      resolve(&Resolvers.Application.get_delegates/3)
    end
  end

  object :delegate do
    field(:id, :id)
    field(:name, :string)
    field(:person_name, :string)
    field(:email, :string)
    field(:address, :string)
    field(:telephone, :string)

    field(:certifier, :certifier) do
      resolve(&Resolvers.Certifier.certifier_item/3)
    end
  end

  object :certifier do
    field(:name, :string)
  end
end
