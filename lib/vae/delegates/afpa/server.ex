defmodule Vae.Delegates.Afpa.Server do
  require Logger
  use GenServer

  @name Afpa

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(delegate) do
    Logger.info("Init #{delegate} server")

    state = %{
      name: delegate,
      data: []
    }

    {:ok, state, {:continue, :get_data}}
  end

  @impl true
  def handle_continue(:get_data, state) do
    data = scrape_calendar()
    updated_state = Map.put(state, :data, data)

    {:noreply, updated_state}
  end

  # def handle_call(:get_academies, _from, state) do
  #   {:reply, FranceVae.get_academies(), state}
  # end

  # def handle_call({:get_meetings, academy_id}, _from, state) do
  #   {:reply, FranceVae.get_meetings(academy_id), state}
  # end

  # def handle_call({:post_meeting_registration, academy_id, meeting_id, user}, _from, state) do
  #   {:reply, FranceVae.post_meeting_registration(academy_id, meeting_id, user), state}
  # end

  def scrape_multiple_pages(nb_of_pages\\5) do
    # TODO
  end

  def scrape_calendar(page\\0, nb_per_page\\12) do
    query_params = %{
      p_p_id: "101_INSTANCE_agenda",
      _101_INSTANCE_agenda_afpa_ddm__22997__DateDebut_en_US: Timex.format!(Timex.today, "%d/%m/%Y", :strftime),
      _101_INSTANCE_agenda_afpa_ddmStructureKey: "EVENEMENT",
      _101_INSTANCE_agenda_categoryId: 58334180,
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
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def scrape_event(url) do
    IO.puts "Scraping #{url}"
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
          }
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
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
end
