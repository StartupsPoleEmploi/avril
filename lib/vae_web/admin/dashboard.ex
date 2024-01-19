defmodule Vae.ExAdmin.Dashboard do
  use ExAdmin.Register

  register_page "Dashboard" do
    menu priority: 1, label: "Statistiques"
    content do
      query = from c in Vae.Certifier, select: [:id, :name], order_by: [:id]

      certifier_id = Vae.String.blank_is_nil(conn.query_params["certifier_id"], &String.to_integer/1)
      certifiers = Vae.Repo.all(query)
      certifier = if certifier_id, do: Vae.Repo.get(Vae.Certifier, certifier_id)
      start_date = Vae.String.blank_is_nil(conn.query_params["start_date"])
      end_date = Vae.String.blank_is_nil(conn.query_params["end_date"])
      type = conn.query_params["type"] || ""

      p ".text-center Citation du jour:"
      h1 "“#{daily_quote()}”"

      hr()
      div ".text-center" do
        Xain.form ".form-inline", [method: "GET", style: "margin-bottom: 1rem;"] do
          Xain.input type: "hidden", name: "type", value: type
          div ".row", [style: "margin-bottom: 1rem"] do
            p "NB: Une semaine démarre le lundi et termine le dimanche."
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
          end
          div ".row", [style: "margin-bottom: 1rem; max-width: 30rem; margin-left: auto; margin-right: auto;"] do
            div ".form-group" do
              label "Certifier : ", [for: "certifier_id", style: "padding-right: 0.5rem;"]
              div ".input-group" do
                div ".input-group-addon" do
                  i ".fa.fa-user"
                end
                Xain.select ".form-control#certifier_id", [name: "certifier_id"] do
                  Xain.option "Sélectionnez un certifier", [value: ""]
                  Enum.map(certifiers, fn c ->
                    Xain.option(c.name, [value: c.id] ++ (if c.id == certifier_id, do: [selected: "selected"], else: []))
                  end)
                end
              end
            end
          end
          div ".row", [style: "margin-bottom: 1rem"] do
            div ".form-group" do
              button "Filtrer", [class: "btn btn-primary", type: "submit"]
            end
          end
        end
      end
      hr()
      div ".section" do
        div [style: "margin-bottom: 4rem;"] do
          a ".btn.btn-default.pull-right #{if type == "booklet", do: "Voir les candidatures", else: "Voir la recevabilité"}", href: "?type=#{if type == "booklet", do: "applications", else: "booklet"}"
        end
        h2 "Candidatures #{if certifier, do: certifier.name} par semaine", [class: "text-center"]
        h4 between_dates_string(start_date, end_date)
        div "#applications-plot.plot-container", ["data-url": "/admin/sql?query=applications&start_date=#{start_date}&end_date=#{end_date}&certifier_id=#{certifier_id}&type=#{type}"]
      end
      hr()
      div ".section" do
        h2 "Candidatures par certifier"
        h4 between_dates_string(start_date, end_date)
        div "#certifiers-table", ["data-url": "/admin/sql?query=certifiers&start_date=#{start_date}&end_date=#{end_date}"]
      end
      hr()
      div ".section" do
        h2 "Candidatures #{if certifier, do: certifier.name} par delegate"
        h4 between_dates_string(start_date, end_date)
        div "#delegates-table", ["data-url": "/admin/sql?query=delegates&start_date=#{start_date}&end_date=#{end_date}&certifier_id=#{certifier_id}"]
      end
      hr()
      div ".section" do
        h2 "Candidatures #{if certifier, do: certifier.name} par certification"
        h4 between_dates_string(start_date, end_date)
        div "#certifications-table", ["data-url": "/admin/sql?query=certifications&start_date=#{start_date}&end_date=#{end_date}&certifier_id=#{certifier_id}"]
      end
      hr()
      div ".section" do
        h2 "Situation actuelle des utilisateurs"
        div "#users-pie", ["data-url": "/admin/sql?query=users"]
      end
    end
  end

  defp daily_quote do
    [
      "Avec l'esprit tranquille, Avril part en exil ❤️"
      # "La Team Avril, elle est pas fragile !",
      # "Avec la team Avril, tout devient facile.",
      # "On est tous agiles, dans la team Avril",
      # "Plus de VAE stériles avec la team Avril",
      # "C'est clair la team Avril, jamais elle se défile",
      # "La team Avril, plus balaise qu'un alterophile",
      # "La team Avril, la VAE c'est son évangile",
      # "Sans la team Avril, combien sont en exil ?",
      # "Jamais la team Avril ne te lâchera d'un fil",
      # "J'te jure la team Avril, c'est la plus fertile",
      # "Partout la team Avril, elle impose son style",
      # "Comment la team Avril, est-elle si habile ?",
      # "Grâce à la team Avril, au revoir l'inutile",
      # "Je fais l'éloge d'Avril, même si ça t'horripile",
      # "Avril ne tremble pas d'un fil",
      # "Avril a les meilleurs devs, ils ne sont pas débiles !"
    ] |> (fn list ->
      daily_index = (
        Timex.today().day() +
        Timex.today().month() +
        Timex.today().year()
      ) |> rem(length(list))
      Enum.at(list, daily_index)
    end).()
  end

  defp between_dates_string(nil, nil), do: "depuis le début des candidatures (avril 2019)"
  defp between_dates_string(start_date, nil), do: "à partir du #{Timex.format!(Timex.parse!(start_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)}"
  defp between_dates_string(nil, end_date), do: "jusqu'au #{Timex.format!(Timex.parse!(end_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)}"
  defp between_dates_string(start_date, end_date), do: "entre le #{Timex.format!(Timex.parse!(start_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)} et le #{Timex.format!(Timex.parse!(end_date, "{YYYY}-{0M}-{0D}"), "%d/%m/%Y", :strftime)}"

end
