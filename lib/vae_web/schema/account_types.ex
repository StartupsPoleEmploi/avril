defmodule VaeWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  alias VaeWeb.Resolvers

  object :account_queries do
    @desc "Returns the current user profile"
    field :identity, :identity do
      resolve(&Resolvers.Account.identity_item/3)
    end
  end

  object :identity do
    field(:gender, :string)
    field(:birthday, :date)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:usage_name, :string)
    field(:email, :string)
    field(:home_phone, :string)
    field(:mobile_phone, :string)
    field(:is_handicapped, :boolean)
    field(:birth_place, :address)
    field(:full_address, :address)
    field(:current_situation, :current_situation)
    field(:nationality, :nationality)
  end

  object :address do
    field(:city, :string)
    field(:county, :string)
    field(:country, :string)
    field(:lat, :float)
    field(:lng, :float)
    field(:street, :string)
    field(:postal_code, :string)
  end

  object :current_situation do
    field(:status, :string)
    field(:employment_type, :string)
    field(:register_to_pole_emploi, :boolean)
    field(:register_to_pole_emploi_since, :date)
    field(:compensation_type, :string)
  end

  object :nationality do
    field(:country, :string)
    field(:country_code, :string)
  end

  object :account_mutations do
    @desc "Updates the current user profile"
    field :update_identity, :identity do
      arg(:input, non_null(:identity_input))
      resolve(&Resolvers.Account.update_item/3)
    end

    @desc "Updates the current user's password"
    field :update_password, :identity do
      arg(:input, non_null(:password_input))
      resolve(&Resolvers.Account.update_password/3)
    end
  end

  input_object :identity_input do
    field(:gender, :string)
    field(:birthday, :date)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:usage_name, :string)
    field(:email, :string)
    field(:home_phone, :string)
    field(:mobile_phone, :string)
    field(:is_handicapped, :boolean)
    field(:birth_place, :address_input)
    field(:full_address, :address_input)
    field(:current_situation, :current_situation_input)
    field(:nationality, :nationality_input)
  end

  input_object :address_input do
    field(:city, :string)
    field(:county, :string)
    field(:country, :string)
    field(:lat, :float)
    field(:lng, :float)
    field(:street, :string)
    field(:postal_code, :string)
  end

  input_object :current_situation_input do
    field(:status, :string)
    field(:employment_type, :string)
    field(:register_to_pole_emploi, :boolean)
    field(:register_to_pole_emploi_since, :date)
    field(:compensation_type, :string)
  end

  input_object :nationality_input do
    field(:country, :string)
    field(:country_code, :string)
  end

  input_object :password_input do
    field(:current_password, non_null(:string))
    field(:password, non_null(:string))
    field(:confirm_password, non_null(:string))
  end
end
