defmodule Vae.Visit do
  use Ecto.Schema
  import Ecto.Changeset

  alias Vae.Search

  @primary_key false
  embedded_schema do
    field(:path_info, {:array, :string})
    field(:certification_id, :integer)
    field(:delegate_id, :integer)

    embeds_one(:search, Search, on_replace: :delete)
  end

  @fields ~w(path_info certification_id delegate_id)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end
end
