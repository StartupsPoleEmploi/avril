defmodule VaeWeb.CertificationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{
    Certification,
    Profession,
    Rome
  }

  alias VaeWeb.Pow.Routes, as: PowRoutes

  def cast_array(str), do: String.split(str, ",") |> Enum.map(&String.to_integer/1)

  filterable do
    @options param: :levels,
             default: [1, 2, 3, 4, 5],
             cast: &VaeWeb.CertificationController.cast_array/1
    filter levels(query, value, _conn) do
      query |> where([c], c.level in ^value)
    end

    @options param: :metier
    filter profession(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :professions))
      |> where([c, r], r.id == ^Vae.String.to_id(value))
    end

    @options param: :rome_code
    filter rome_code(query, value, _conn) do
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.code == ^Vae.String.to_id(value))
    end
  end

  def index(conn, params) do
    with(
      {:ok, filtered_query, filter_values} <- apply_filters(Certification, conn),
      page <- Repo.paginate(filtered_query, params)
    ) do
      render(
        conn,
        "index.html",
        %{
          certifications: page.entries,
          no_results: count_without_level_filter(params) == 0,
          page: page
        }
        |> Map.merge(enrich_filter_values(filter_values))
      )
    end
  end

  def show(conn, %{"id" => id} = _params) do
    with(
      {id, rest} <- Integer.parse(id),
      slug <- Regex.replace(~r/^\-/, rest, ""),
      certification when not is_nil(certification) <- Repo.get(Certification, id)
    ) do
      if certification.slug != slug do
        # Slug is not up-to-date
        redirect(conn,
          to: Routes.certification_path(conn, :show, certification, conn.query_params)
        )
      else
        certification =
          Repo.preload(certification, [:certifiers, romes: [certifications: :certifiers]])

        similars =
          certification
          |> Map.get(:romes)
          |> Enum.flat_map(fn r -> r.certifications end)
          |> Enum.reject(fn c -> c.id == certification.id end)
          |> Enum.sort_by(
            fn c ->
              common_certifiers =
                Enum.filter(certification.certifiers, fn el -> Enum.member?(c.certifiers, el) end)

              level_diff_ratio = (4 - abs(certification.level - c.level)) / 4
              length(common_certifiers) + level_diff_ratio
            end,
            &>=/2
          )
          |> Enum.take(3)

        render(
          conn,
          "show.html",
          certification: certification,
          similars: similars
        )
      end
    else
      _error ->
        raise Ecto.NoResultsError, queryable: Certification
    end
  end

  def select(conn, %{"certification_id" => certification_id} = _params) do
    certification_id = Vae.String.to_id(certification_id)
    conn
    |> Plug.Conn.put_session(:certification_id, certification_id)
    |> PowRoutes.maybe_create_application_and_redirect(certification_id)
  end

  defp enrich_filter_values(%{rome_code: rome_code} = filters) do
    rome = Repo.get_by(Rome, code: Vae.String.to_id(rome_code)) |> Repo.preload(:professions)

    Map.merge(filters, %{
      rome: rome,
      subcategory: Rome.subcategory(rome),
      category: Rome.category(rome)
    })
  end

  defp enrich_filter_values(%{profession: profession_id} = filters) do
    profession = Repo.get(Profession, Vae.String.to_id(profession_id))

    Map.merge(filters, %{
      profession: profession,
      # rome: profession.rome,
      # subcategory: Rome.subcategory(profession.rome),
      # category: Rome.category(profession.rome)
    })
  end

  defp enrich_filter_values(filters), do: filters

  defp count_without_level_filter(params) do
    conn_without_filter_level = %Plug.Conn{
      params: Map.drop(params, ["levels"])
    }

    with {:ok, filtered_query, _filter_values} <-
           apply_filters(
             Certification,
             conn_without_filter_level
           ) do
      Repo.aggregate(filtered_query, :count, :id)
    end
  end
end