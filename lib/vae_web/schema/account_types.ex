defmodule VaeWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :account_queries do
    @desc "Returns the current user profile"
    field :profile, :profile do
      resolve(&Resolvers.Account.profile_item/3)
    end
  end

  object :profile do
    field(:gender, :string)
    field(:birthday, :date)
    field(:birth_place, :address)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:phone_number, :string)
    field(:full_address, :address)
  end

  object :address do
    field(:street, :string)
    field(:postal_code, :string)
    field(:city, :string)
    field(:country, :string)
  end
end
