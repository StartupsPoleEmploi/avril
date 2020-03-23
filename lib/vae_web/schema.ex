defmodule VaeWeb.Schema do
  use Absinthe.Schema

  alias Vae.Applications

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
  end

  #        %{
  #        # id: application.id,
  #        booklet_hash: application.booklet_hash,
  #        certification:
  #          application.certification
  #          |> Maybe.map(
  #            &%{
  #              slug: &1.slug,
  #              name: Certification.name(&1),
  #              level: ViewHelpers.level_info_by_level(&1.level)
  #            }
  #          ),
  #        delegate:
  #          application.delegate
  #          |> Maybe.map(
  #            &%{
  #              name: &1.name,
  #              certifier_name: &1.certifiers |> hd() |> Maybe.map(fn c -> c.name end),
  #              address: &1.address
  #            }
  #          ),
  #        created_at: application.inserted_at
  #      }
end
