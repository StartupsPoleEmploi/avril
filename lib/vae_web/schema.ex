defmodule VaeWeb.Schema do
  use Absinthe.Schema

  alias Vae.{Applications, Authorities}
  alias VaeWeb.Resolvers

  import_types(Absinthe.Type.Custom)

  @desc "List user applications"
  query do
    field(:applications, list_of(:application)) do
      resolve(&Resolvers.Application.application_items/3)
    end

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
