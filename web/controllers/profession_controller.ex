defmodule Vae.ProfessionController do
  require Logger

  use Vae.Web, :controller

  alias Vae.Profession

  def index(conn, params) do
    page =
      Profession
      |> Profession.search(params["search"]["for"])
      |> Repo.paginate(params)

    render(conn, "index.html",
      professions: page.entries,
      page: page,
      search_terms: params["search"]["for"]
    )
  end
end
