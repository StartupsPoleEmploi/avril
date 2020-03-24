defmodule VaeWeb.Schema do
  use Absinthe.Schema

  alias VaeWeb.Resolvers

  import_types(Absinthe.Type.Custom)

  query do
    @desc "List user applications"
    field(:applications, list_of(:application)) do
      resolve(&Resolvers.Application.application_items/3)
    end

    @desc "Returns an application by its id only if the current user is the owner"
    field(:application, :application) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Application.application/3)
    end

    @desc "Returns the list of delegates from the closest to the furthest from the postal code of the user and the application id"
    field(:delegate_search, list_of(:delegate)) do
      arg(:application_id, non_null(:id))
      resolve(&Resolvers.Application.get_delegates/3)
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

  object :certification do
    field(:id, :id)
    field(:slug, :string)
    field(:acronym, :string)
    field(:label, :string)
    field(:level, :string)
  end

  object :certifier do
    field(:name, :string)
  end
end
