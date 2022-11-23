defmodule VaeWeb.CertificationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{
    Certification,
    Profession,
    Repo,
    Rome,
    User,
    UserApplication
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
             default: nil
    filter rome_code(query, value, _conn) do
      code = Vae.String.to_id_string(value)
      query
      |> join(:inner, [r], r in assoc(r, :romes))
      |> where([c, r], r.code == ^code)
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
    with(
      {:ok, filtered_query, filter_values} <- apply_filters(Certification.searchable_query(), conn),
      by_level_total <- count_with_level(filtered_query),
      ordered_query <- Certification.sort_by_popularity(filtered_query),
      page <- Repo.paginate(ordered_query, Map.merge(params, %{page_size: 9}))
    ) do

      render(
        conn,
        "index.html",
        %{
          certifications: page.entries,
          by_level_total: by_level_total,
          page: page,
          params: params,
          level: nil
        } |> Map.merge(enrich_filter_values(filter_values))
      )
    end
  end

  def show(conn, %{"id" => id} = params) do
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
        %Certification{is_active: is_active} = certification =
          Repo.preload(certification, [:delegates, romes: [:active_certifications]])

        nb_similars = if is_active and length(certification.delegates) > 0, do: 3, else: 6

        similars =
          Certification.searchable_query()
          |> join(:left, [c], r in assoc(c, :romes))
          |> where([c, r], r.id in ^Enum.map(certification.romes, &(&1.id)))
          |> where([c, r], c.id != ^certification.id)
          |> Certification.sort_by_popularity()
          |> limit(^nb_similars)
          |> Repo.all()

        existing_application = case Pow.Plug.current_user(conn) do
          nil -> nil
          %User{id: user_id} ->
            Repo.get_by(UserApplication, user_id: user_id, certification_id: id)
        end

        transferable_applications = if params["transferable"], do: User.transferable_applications(Pow.Plug.current_user(conn)), else: []

        render(
          conn,
          "show.html",
          transferable_applications: transferable_applications,
          existing_application: existing_application,
          is_asp: Certification.is_asp?(certification),
          certification: certification,
          similars: similars
        )
      end
    else
      nil ->
        conn
        |> put_flash(:warning, "La certification demandée n'a pas été trouvée. Merci d'effectuer une nouvelle recherche.")
        |> redirect(to: Routes.root_path(conn, :index))
    end
  end

  def select(conn, %{"certification_id" => certification_id} = params) do
    certification_id = Vae.String.to_id(certification_id)

    transferable_applications = User.transferable_applications(Pow.Plug.current_user(conn))

    if length(transferable_applications) > 0 && params["user_application_id"] != "new" do
      if params["user_application_id"] do
        {:ok, user_application} = Repo.get(UserApplication, params["user_application_id"])
        |> UserApplication.changeset(%{
          certification_id: certification_id,
          delegate_id: nil,
        })
        |> Repo.update()

        redirect(conn, external: Vae.User.profile_url(conn, user_application))
      else
        redirect(conn, to: Routes.certification_path(conn, :show, certification_id, transferable: ""))
      end
    else
      conn
      |> Plug.Conn.put_session(:certification_id, certification_id)
      |> VaeWeb.RegistrationController.maybe_create_application_and_redirect(true)
    end

  end

  defp enrich_filter_values(%{rome_code: rome_code} = filters) do
    case Repo.get_by(Rome, code: Vae.String.to_id_string(rome_code)) |> Repo.preload(:professions) do
      %Rome{} = rome ->
        Rome.increase_views(rome)

        Map.merge(filters, %{
          rome: rome,
          subcategory: Rome.subcategory(rome),
          category: Rome.category(rome)
        })
      _ -> filters
    end
  end

  defp enrich_filter_values(%{profession: profession_id} = filters) do

    case Repo.get(Profession, profession_id) |> Repo.preload(:rome) do
      %Profession{rome: rome} = profession ->
        Rome.increase_views(rome)

        Map.merge(filters, %{
          profession: profession
        })
      _ -> filters
    end
  end

  defp enrich_filter_values(filters), do: filters

  def count_with_level(query) do
    levels = Enum.to_list(3..8)

    counts = from(c in query, [
      where: c.level in ^levels,
      select: %{
        level: c.level,
        count: count(c.id)
      },
      group_by: c.level
    ]) |> Repo.all()

    Enum.reduce(levels, %{total: 0}, fn level, result ->
      value = counts
      |> Enum.find(&(&1.level == level))
      |> case do
        %{count: count} when is_integer(count) -> count
        _ -> 0
      end

      result
      |> Map.put(
        level,
        value
      )
      |> Map.put(:total, result.total + value)
    end)
  end
end
