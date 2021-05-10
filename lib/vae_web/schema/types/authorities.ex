defmodule VaeWeb.Schema.Types.Authorities do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :authorities_queries do
    @desc "Returns the list of delegates from the closest to the furthest from the postal code of the user and the application ID"
    field(:delegates_search, list_of(:delegate)) do
      arg(:application_id, non_null(:id))
      arg(:geo, non_null(:geo_input))
      arg(:radius, :integer)
      arg(:administrative, :string)
      # arg(:postal_code, non_null(:string))

      resolve(&Resolvers.Application.delegates_search/3)
    end

    field(:meetings_search, list_of(:meeting)) do
      arg(:delegate_id, non_null(:id))
      # arg(:geo, non_null(:geo_input))
      # arg(:radius, :integer)
      # arg(:administrative, :string)
      # arg(:postal_code, non_null(:string))

      resolve(&Resolvers.Application.meetings_search/3)
    end
  end

  object :delegate do
    field(:id, :id)
    field(:is_active, :boolean)
    field(:name, :string)
    field(:person_name, :string)
    field(:email, :string)
    field(:address_name, :string)
    field(:address, :string)
    field(:telephone, :string)
    field(:website, :string)
    field(:external_notes, :string)
  end

  object :meeting do
    field(:academy_id, :integer)
    field(:address, :string)
    field(:city, :string)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:meeting_id, :string)
    field(:place, :string)
    field(:postal_code, :string)
    field(:remaining_places, :integer)
    field(:target, :string)
  end

  object :certifier do
    field(:name, :string)
    field(:external_notes, :string)
  end

  input_object :geo_input do
    field(:lat, non_null(:float))
    field(:lng, non_null(:float))
  end
end
