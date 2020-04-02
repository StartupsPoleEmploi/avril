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

    field(:meeting, :meeting)

    field(:delegate, :delegate)
    field(:certification, :certification)
  end

  object :meeting do
    field(:name, :string)
    field(:academy_id, :integer)
    field(:meeting_id, :integer)
    field(:place, :string)
    field(:address, :string)
    field(:postal_code, :string)
    field(:city, :string)
    field(:target, :string)
    field(:remaining_places, :integer)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
  end

  object :application_mutations do
    @desc "Attach a delegate to an application"
    field(:attach_delegate, :application) do
      arg(:input, non_null(:attach_delegate_input))
      resolve(&Resolvers.Application.attach_delegate/3)
    end
  end

  input_object :attach_delegate_input do
    field(:application_id, non_null(:id))
    field(:delegate_id, non_null(:id))
  end
end
