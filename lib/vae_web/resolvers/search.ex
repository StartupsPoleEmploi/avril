defmodule VaeWeb.Resolvers.Search do

  alias Vae.{Certification, Profession, Repo}
  import Ecto.Query

  def certification(_, %{input: params}, _) do
    {:ok, where_like(Certification, ~w(acronym label)a, params)}
  end

  def profession(_, %{input: params}, _) do
    {:ok, where_like(Certification, ~w(label)a, params)}
  end

  defp where_like(entity, searchable_fieds, query) do
    # IO.inspect(query)
    # |> IO.inspect()
    # |> Enum.with_index()

    # searchable_fieds
    # |> Enum.reduce(from(e in entity), fn field_name, query ->
    #   IO.inspect(field_name)
    #   IO.inspect(query)
    #   or_where(query, [e], like(field(e, ^field_name), ^"%#{query}%"))
    # end)
    from(e in entity)
    |> or_where([e], ilike(field(e, :label), ^"%#{query}%"))
    |> limit(10)
    |> Repo.all()
  end
end
