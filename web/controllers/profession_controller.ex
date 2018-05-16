defmodule Vae.ProfessionController do
  require Logger

  use Vae.Web, :controller

  alias Vae.Profession
  alias Vae.Suggest

  def index(conn, params) do
    page = Profession
           |> Profession.search(params["search"]["for"])
           |> Repo.paginate(params)

    render(conn, "index.html", professions: page.entries, page: page, search_terms: params["search"]["for"])
  end

  def suggest(conn, params) do
    with {:ok, professions} <- params["search"]["for"] |> Suggest.get_suggest do
      json conn, professions
    else
      _ ->
        Logger.error "Cannot retrieve rome from LBB"

        {_, professions} = Profession
                           |> Profession.search(params["search"]["for"])
                           |> Repo.all()
                           |> Enum.flat_map_reduce([], fn profession, acc ->
                                {[profession], acc ++ [%{value: String.downcase(profession.label),
                                                         id: profession.rome.code}]}
                           end)

        json conn, professions
    end
  end
end
