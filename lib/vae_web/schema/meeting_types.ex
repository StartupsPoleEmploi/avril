defmodule VaeWeb.Schema.MeetingTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :meeting_queries do
    @desc "List meetings form a delegate location"
    field(:meetings, list_of(:meeting_place)) do
      arg(:delegate_id, non_null(:id))
      resolve(&Resolvers.Meeting.meeting_items/3)
    end
  end

  object :meeting_place do
    field(:name, :string)
    field(:meetings, list_of(:meeting))
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
end
