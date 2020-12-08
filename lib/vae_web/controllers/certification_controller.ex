defmodule VaeWeb.CertificationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{
    Certification,
    Profession,
    Repo,
    Rome
  }

  def cast_array(str), do: String.split(str, ",") |> Enum.map(&String.to_integer/1)

  filterable do
    @options param: :level,
             default: nil,
             cast: &String.to_integer/1
    filter level(query, value, _conn) do
      query |> where([c], c.level == ^value)
    end

    @options param: :metier,
             default: nil,
             cast: &Vae.String.to_id/1
    filter profession(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :professions))
      |> where([c, r], r.id == ^value)
    end

    @options param: :rome_code,
             default: nil,
             cast: &Vae.String.to_id/1
    filter rome_code(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.code == ^value)
    end
  end

  @doc "List certifications from search query parameter"
  @deprecated "Use index with :level / :metier / :rome_code query parameters"
  def index(conn, %{"search" => search} = params) do
    params =
      params
      |> Map.delete("search")
      |> Map.put("rome_code", search["rome_code"])

    redirect(conn, to: Routes.certification_path(conn, :index, params))
  end

  def index(conn, params) do
    active_certifications_query = from c in Certification, where: [is_active: true]
    with(
      {:ok, filtered_query, filter_values} <- apply_filters(active_certifications_query, conn),
      total <- Repo.aggregate(filtered_query, :count, :id),
      by_level_total <- count_with_level(filtered_query),
      ordered_query <- Certification.sort_by_popularity(filtered_query),
      page <- Repo.paginate(ordered_query, Map.merge(params, %{page_size: 9}))
    ) do
      render(
        conn,
        "index.html",
        %{
          certifications: page.entries,
          total: total,
          by_level_total: by_level_total,
          page: page,
          params: params,
          level: nil
        }
        |> Map.merge(enrich_filter_values(filter_values))
      )
    end
  end

  def show(conn, %{"id" => id} = _params) do
    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      certification <- Repo.get!(Certification, id)
    ) do
      if certification.slug != slug do
        # Slug is not up-to-date
        redirect(conn,
          to: Routes.certification_path(conn, :show, certification, conn.query_params)
        )
      else
        %Certification{is_active: is_active} = certification =
          Repo.preload(certification, [:certifiers, romes: [active_certifications: :certifiers]])

        nb_similars = if is_active, do: 3, else: 6

        similars =
          from(c in Certification)
          |> join(:left, [c], r in assoc(c, :romes))
          |> where([c, r], r.id in ^Enum.map(certification.romes, &(&1.id)))
          |> where([c, r], c.id != ^certification.id)
          |> Certification.sort_by_popularity()
          |> limit(^nb_similars)
          |> Repo.all()

        render(
          conn,
          "show.html",
          certification: certification,
          similars: similars
        )
      end
    end
  end

  def select(conn, %{"certification_id" => certification_id} = _params) do
    certification_id = Vae.String.to_id(certification_id)

    conn
    |> Plug.Conn.put_session(:certification_id, certification_id)
    |> VaeWeb.RegistrationController.maybe_create_application_and_redirect(certification_id)
  end

  defp enrich_filter_values(%{rome_code: rome_code} = filters) do
    rome = Repo.get_by(Rome, code: Vae.String.to_id(rome_code)) |> Repo.preload(:professions)

    if rome do
      Map.merge(filters, %{
        rome: rome,
        subcategory: Rome.subcategory(rome),
        category: Rome.category(rome)
      })
    else
      filters
    end
  end

  defp enrich_filter_values(%{profession: profession_id} = filters) do
    profession = Repo.get(Profession, Vae.String.to_id(profession_id))

    Map.merge(filters, %{
      profession: profession
    })
  end

  defp enrich_filter_values(filters), do: filters

  def count_with_level(query) do
    Enum.reduce(3..8, %{}, fn level, result ->
      count =
        from(c in query, [where: c.level == ^level])
        |> Repo.aggregate(:count, :id)

      Map.put(result, level, count)
    end)
  end
end
