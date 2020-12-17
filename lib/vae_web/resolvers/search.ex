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
    from(e in entity)
    |> or_where([e], ilike(field(e, :label), ^"%#{query}%"))
    |> limit(10)
    |> Repo.all()
  end
end
