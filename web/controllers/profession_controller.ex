defmodule Vae.ProfessionController do
  require Logger

  use Vae.Web, :controller

  alias Vae.{
    Repo,
    Profession
  }

  filterable do
    @options param: [:sort, :order], default: [sort: :label, order: :asc]
    filter search(query, %{sort: field, order: order}, _conn) do
      order_by(query, [{^order, ^field}])
    end

    # @options param: :levels,
    #          default: [1, 2, 3, 4, 5],
    #          cast: &(String.split(&1, ","))
    # filter levels(query, value, _conn) do
    #   query |> where([c], c.level in ^value)
    # end
  end

  def show(conn, %{"id" => id} = params) do
    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      profession when not is_nil(profession) <- Repo.get(Profession, id)
    ) do
      if profession.slug != slug do
        # Slug is not up-to-date
        redirect(conn, to: Routes.profession_path(conn, :show, profession, conn.query_params))
      else
        render(conn, "show.html",
          profession: profession,
          certifications: Profession.get_certifications(profession)
        )
      end
    else
      _error ->
        raise Ecto.NoResultsError, queryable: Profession
    end
  end
end
