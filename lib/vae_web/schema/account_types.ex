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

  object :account_mutations do
    @desc "Updates the current user profile"
    field :update_profile, :profile do
      arg(:input, non_null(:profile_input))
      resolve(&Resolvers.Account.update_item/3)
    end

    @desc "Updates the current user's password"
    field :update_password, :profile do
      arg(:input, non_null(:password_input))
      resolve(&Resolvers.Account.update_password/3)
    end
  end

  input_object :profile_input do
    field(:gender, :string)
    field(:birthday, :date)
    field(:birth_place, :address_input)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:email, :string)
    field(:phone_number, :string)
    field(:full_address, :address_input)
  end

  input_object :address_input do
    field(:street, :string)
    field(:postal_code, :string)
    field(:city, :string)
    field(:country, :string)
  end

  input_object :password_input do
    field(:current_password, non_null(:string))
    field(:password, non_null(:string))
    field(:confirm_password, non_null(:string))
  end
end
