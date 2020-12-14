defmodule VaeWeb.Schema.Types.Search do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :public_searches do
    @desc "Returns certification search results"
    field :public_certifications_search, list_of(:certification) do
      arg(:input, non_null(:string))
      resolve(&Resolvers.Search.certification/3)
    end

    @desc "Returns profession search results"
    field :public_professions_search, list_of(:profession) do
      arg(:input, non_null(:string))
      resolve(&Resolvers.Search.profession/3)
    end
  end
end
