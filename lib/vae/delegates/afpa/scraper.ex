defmodule Vae.Delegates.Afpa.Scraper do
  require Logger
  import Ecto.Query

  def scrape_all_events(page\\0) do
    case scrape_page_events(page) do
      [] -> []
      events when is_list(events) -> events ++ scrape_all_events(page+1)
      _ -> []
    end
  end

  def scrape_page_events(page\\0, nb_per_page\\12) do
    Logger.info "Scraping page #{page}"
    query_params = %{
      p_p_id: "101_INSTANCE_agenda",
      _101_INSTANCE_agenda_afpa_ddm__22997__DateDebut_en_US: Timex.format!(Timex.today, "%d/%m/%Y", :strftime),
      _101_INSTANCE_agenda_afpa_ddmStructureKey: "EVENEMENT",
      _101_INSTANCE_agenda_categoryId: 58_334_180,
      _101_INSTANCE_agenda_afpa_start: page * nb_per_page,
      _101_INSTANCE_agenda_afpa_rows: nb_per_page
    }

    case HTTPoison.get("https://www.afpa.fr/agenda?#{URI.encode_query(query_params)}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Floki.find(".evenement figcaption .lirelasuite")
        |> Floki.attribute("id")
        |> Enum.map(fn id -> scrape_event("https://www.afpa.fr/agenda/#{id}") end)
        |> Enum.filter(fn meeting -> !is_nil(meeting) end)
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.warn "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error reason
    end
  end

  def scrape_event(url) do
    Logger.info "Scraping #{url}"
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        custom_back = Floki.find(body, ".custom-back")
        info_node_children = Floki.find(custom_back, ".center-info") |> node_children()
        time_node_children = Floki.find(custom_back, ".date-info span:last-child") |> node_children()

        if is_nil(info_node_children) || is_nil(time_node_children) do
          nil
        else
          [name, address, postal_city] =
            info_node_children

            |> filter_nodes_by_tag_name("br")
            |> Enum.map(fn node ->
              Floki.text(node)
              |> String.replace(~r/\r|\n|\t/, "")
              |> String.replace(~r/\s+/, " ")
              |> String.trim()
            end)

          [postal_code, city] = String.split(postal_city, " ", parts: 2)

          [date, time] =
            time_node_children
            |> filter_nodes_by_tag_name("br")
            |> Enum.map(fn node ->
              Floki.text(node)
              |> String.replace(~r/\r|\n|\t/, "")
              |> String.replace(~r/\s+/, " ")
              |> String.trim()
            end)

          %{
            datetime: format_date(date, time),
            name: name,
            address: address,
            postal_code: String.to_integer(postal_code),
            city: city
          } |> Map.merge(%{geolocation: Vae.Places.Client.Algolia.get_geoloc_from_address("#{address} #{postal_code} #{city}")})
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.warn "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error reason
    end
  end


  defp node_children(node_list) do
    case List.first(node_list) do
      node when is_tuple(node) -> elem(node, 2)
      _ -> nil
    end
  end

  defp filter_nodes_by_tag_name(node_list, tag_name), do: node_list |> Enum.filter(
    fn
      node when is_tuple(node) -> elem(node, 0) != tag_name
      node -> true
    end
  )
  defp format_date(french_date, time) do
    %{"number" => number, "month_name" => month_name} = Regex.named_captures(~r/[a-z]+ (?<number>\d+) (?<month_name>\D+)/, String.downcase(french_date))
    [hours, minutes] = String.split(time, ":", parts: 2)
    Timex.parse!("#{String.pad_leading(number, 2, "0")}/#{french_month_to_integer(month_name)}/#{Timex.today.year} #{String.pad_leading(hours, 2, "0")}:#{String.pad_leading(minutes, 2, "0")}", "%d/%m/%Y %H:%M", :strftime)
  end

  defp french_month_to_integer(french_month) do
    months = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    Enum.find_index(months, fn fm -> fm == french_month end) + 1
    |> Integer.to_string
    |> String.pad_leading(2, "0")
  end

  def match_events_with_delegates(meetings) do
    afpas = Vae.Repo.all(from d in Vae.Delegate, where: like(d.slug, ^"%afpa%"))
    Enum.map(meetings, fn meeting -> Map.merge(meeting, %{
      afpas: Enum.filter(afpas, fn afpa -> calc_distance_from_coords(
        meeting.geolocation["_geoloc"]["lat"],
        meeting.geolocation["_geoloc"]["lng"],
        afpa.geolocation["_geoloc"]["lat"],
        afpa.geolocation["_geoloc"]["lng"]
      ) < 50 end)
    }) end)
  end

  defp calc_distance_from_coords(lat1, lng1, lat2, lng2) do
    dLat = deg2rad(lat2-lat1)
    dLon = deg2rad(lng2-lng1)
    a =
      :math.sin(dLat/2) * :math.sin(dLat/2) +
      :math.cos(deg2rad(lat1)) * :math.cos(deg2rad(lat2)) *
      :math.sin(dLon/2) * :math.sin(dLon/2)
      ;
    2 * :math.atan2(:math.sqrt(a), :math.sqrt(1-a)) * 6_371 # Radius of the earth in km
  end

  defp deg2rad(deg), do: deg * (:math.pi/180)

end