defmodule Vae.ExAdmin.Dashboard do
  use ExAdmin.Register

  register_page "Dashboard" do
    menu priority: 1, label: "Statistiques"
    content do
      start_date = conn.query_params["start_date"]
      end_date = conn.query_params["end_date"]
      type = conn.query_params["type"] || "submissions"

      p ".text-center Citation du jour:"
      h1 "“#{daily_quote()}”"
      hr

      div ".text-center" do
        p "Voir les chiffres sur une période données :"
        Xain.form ".form-inline", [method: "GET", style: "margin-bottom: 1rem;"] do
          div ".form-group" do
            label "Date de début :", [for: "start_date", style: "padding-right: 0.5rem;"]
            div ".input-group" do
              div ".input-group-addon" do
                i ".fa.fa-calendar"
              end
              Xain.input ".datepicker.form-control#start_date", [name: "start_date", value: start_date, autocomplete: "off", "data-date-week-start": 1]
            end
          end
          div ".form-group" do
            label "Date de fin : ", [for: "end_date", style: "padding-right: 0.5rem;"]
            div ".input-group" do
              div ".input-group-addon" do
                i ".fa.fa-calendar"
              end
              Xain.input ".datepicker.form-control#end_date", [name: "end_date", value: end_date, autocomplete: "off", "data-date-week-start": 1]
            end
          end
          div ".form-group" do
            button "Filtrer sur les dates", [class: "btn btn-primary", type: "submit"]
          end
        end
        p "Une semaine démarre le lundi et termine le dimanche."
      end
      hr
      div ".section" do
        div ".pull-right" do
          Xain.form [method: "GET"] do
            Xain.button (if type == "submissions",  do: "Vue Livret 1", else: "Vue Transmissions"), [type: "submit", name: "type", value: (if type == "submissions",  do: "booklet", else: "submissions"), class: "btn btn-primary"]
          end
        end
        div ".clearfix" do
          h2 "Candidatures par semaines", [class: "text-center"]
          p between_dates_string(start_date, end_date)
          div "#applications-plot.plot-container", ["data-url": "/admin/sql?query=applications&start_date=#{start_date}&end_date=#{end_date}&type=#{type}"]
        end
      end
      hr
      div ".section" do
        h2 "Candidatures par certificateurs"
        p between_dates_string(start_date, end_date)
        div "#delegates-table", ["data-url": "/admin/sql?query=delegates&start_date=#{start_date}&end_date=#{end_date}"]
      end
      hr
      div ".section" do
        h2 "Candidatures par certifications"
        p between_dates_string(start_date, end_date)
        div "#certifications-table", ["data-url": "/admin/sql?query=certifications&start_date=#{start_date}&end_date=#{end_date}"]
      end
    end
  end

  defp daily_quote do
    [
      "La Team Avril, elle est pas fragile !",
      "Avec la team Avril, tout devient facile.",
      "On est tous agile, dans la team Avril",
      "Plus de VAE stériles avec la team Avril",
      "C'est clair la team Avril, jamais elle se défile",
      "La team Avril, plus balaise qu'un alterophile",
      "La team Avril, la VAE c'est son évangile",
      "Sans la team Avril, combien sont en exil ?",
      "Jamais la team Avril ne te lâchera d'un fil",
      "J'te jure la team Avril, c'est la plus fertile",
      "Partout la team Avril, elle impose son style",
      "Comment la team Avril, est-elle si habile ?",
      "Grâce à la team Avril, au revoir l'inutile",
      "Je fais l'éloge d'Avril, même si ça t'horripile",
      "Avril ne tremble pas d'un fil",
      "Avril a les meilleurs devs, ils ne sont pas débiles !"
    ] |> (fn list ->
      daily_index = (
        Timex.today().day() +
        Timex.today().month() +
        Timex.today().year()
      ) |> rem(length(list))
      Enum.at(list, daily_index)
    end).()
  end

  defp between_dates_string(nil, nil), do: ""
  defp between_dates_string(start_date, nil), do: "à partir du #{Timex.format!(Timex.parse!(start_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)}"
  defp between_dates_string(nil, end_date), do: "jusqu'au #{Timex.format!(Timex.parse!(end_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)}"
  defp between_dates_string(start_date, end_date), do: "entre le #{Timex.format!(Timex.parse!(start_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)} et le #{Timex.format!(Timex.parse!(end_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)}"

end
