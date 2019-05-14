defmodule Vae.ProfessionController do
  require Logger

  use Vae.Web, :controller

  alias Vae.Profession

  def index(conn, params) do
    page =
      Profession
      |> preload(:rome)
      |> Repo.paginate(params)

    render(conn, "index.html",
      professions: page.entries,
      page: page,
      with_search: false
    )
  end
end
