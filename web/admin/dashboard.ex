defmodule Vae.ExAdmin.Dashboard do
  use ExAdmin.Register
  import Ecto.Query

  register_page "Dashboard" do
    menu priority: 1, label: "Statistiques"
    content do
      applications =  %{
        total: Vae.Repo.aggregate((from p in Vae.Application), :count, :id),
        submitted: Vae.Repo.aggregate((from p in Vae.Application, where: not is_nil(p.submitted_at)), :count, :id),
        admissibles: Vae.Repo.aggregate((from p in Vae.Application, where: not is_nil(p.admissible_at)), :count, :id),
        inadmissibles: Vae.Repo.aggregate((from p in Vae.Application, where: not is_nil(p.inadmissible_at)), :count, :id),
        simple_contact_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: is_nil(p.delegate_access_hash)), :inserted_at) |> Vae.Repo.all,
        unsubmitted_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: is_nil(p.admissible_at) and is_nil(p.inadmissible_at) and is_nil(p.submitted_at) and not is_nil(p.delegate_access_hash)), :inserted_at) |> Vae.Repo.all,
        submitted_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: not is_nil(p.submitted_at) and is_nil(p.admissible_at) and is_nil(p.inadmissible_at) and not is_nil(p.delegate_access_hash)), :inserted_at) |> Vae.Repo.all,
        admissible_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: not is_nil(p.submitted_at) and not is_nil(p.admissible_at) and not is_nil(p.delegate_access_hash)), :inserted_at) |> Vae.Repo.all,
        inadmissible_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: not is_nil(p.submitted_at) and not is_nil(p.inadmissible_at) and not is_nil(p.delegate_access_hash)), :inserted_at) |> Vae.Repo.all,
      } |> (&(Map.put(&1, :admissibles_ratio, :erlang.float_to_binary(100 * &1.admissibles / (&1.admissibles + &1.inadmissibles), [decimals: 2])))).()
        |> (&(Map.put(&1, :inadmissibles_ratio, :erlang.float_to_binary(100 * &1.inadmissibles / (&1.admissibles + &1.inadmissibles), [decimals: 2])))).()
        |> (&(Map.put(&1, :submitted_ratio, :erlang.float_to_binary(100 * &1.submitted / (&1.total), [decimals: 2])))).()

      p ".text-center Citation du jour:"
      h1 "La Team Avril, elle est pas fragile !"
      hr
      div ".section" do
        h2 "Candidatures par certificateurs"
        div "#delegates-table", ["data-url": "/admin/sql?query=delegates"]
      end
      div ".section" do
        h2 "Candidatures par certifications"
        div "#certifications-table", ["data-url": "/admin/sql?query=certifications"]
      end
      hr
      div ".section" do
        h2 "Candidatures dans le temps"
        p "#{applications.total} candidatures dont #{applications.submitted} soumises (#{applications.submitted_ratio}%) dont #{applications.admissibles} admissibles et #{applications.inadmissibles} rejetées soit #{applications.admissibles_ratio}% d'acceptation."
        div "#applications-plot.plot-container" do
          pre do
            Jason.encode!([%{
              name: "Simple contact",
              color: "#2980b9",
              data: applications.simple_contact_week_array
            }, %{
              name: "Profil enrichi non-transmis",
              color: "#e67e22",
              data: applications.unsubmitted_week_array
            }, %{
              name: "Profil enrichi transmis",
              color: "#bdc3c7",
              data: applications.submitted_week_array
            }, %{
              name: "Admissible après relance",
              color: "#2ecc71",
              data: applications.admissible_week_array
            }, %{
              name: "Refusé après relance",
              color: "#c0392b",
              data: applications.inadmissible_week_array
            }], pretty: true)
          end
          div ".plot"
        end
      end
    end
  end
end
