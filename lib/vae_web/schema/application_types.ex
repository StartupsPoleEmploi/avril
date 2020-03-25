defmodule VaeWeb.Schema.ApplicationTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :application_queries do
    @desc "List user applications"
    field(:applications, list_of(:application)) do
      resolve(&Resolvers.Application.application_items/3)
    end

    @desc "Returns an application by its id only if the current user is the owner"
    field(:application, :application) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.application/3)
    end
  end

  object :application do
    field(:id, :id)
    field(:booklet_hash, :string)
    field(:inserted_at, :naive_datetime)
    field(:submitted_at, :naive_datetime)

    field(:delegate, :delegate)
    field(:certification, :certification)
  end
end
