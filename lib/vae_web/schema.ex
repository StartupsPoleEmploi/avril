defmodule VaeWeb.Schema do
  use Absinthe.Schema

  alias Vae.{Applications, Authorities}

  import_types(Absinthe.Type.Custom)

  @desc "List user applications"
  query do
    field(:applications, list_of(:application)) do
      resolve(fn _, _, %{context: %{current_user: user}} ->
        {:ok, Applications.get_applications(user.id)}
      end)
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
      resolve(fn delegate, _, _ ->
        {:ok, Authorities.get_first_certifier_from_delegate(delegate)}
      end)
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
