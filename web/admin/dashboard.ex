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
        unknown_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: is_nil(p.admissible_at) and is_nil(p.inadmissible_at) and is_nil(p.submitted_at)), :inserted_at) |> Vae.Repo.all,
        submitted_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: not is_nil(p.submitted_at) and is_nil(p.admissible_at) and is_nil(p.inadmissible_at)), :inserted_at) |> Vae.Repo.all,
        admissible_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: not is_nil(p.submitted_at) and not is_nil(p.admissible_at)), :inserted_at) |> Vae.Repo.all,
        inadmissible_week_array: Vae.Application.count_by_week((from p in Vae.Application, where: not is_nil(p.submitted_at) and not is_nil(p.inadmissible_at)), :inserted_at) |> Vae.Repo.all,
      } |> (&(Map.put(&1, :admissibles_ratio, :erlang.float_to_binary(100 * &1.admissibles / (&1.admissibles + &1.inadmissibles), [decimals: 2])))).()
        |> (&(Map.put(&1, :inadmissibles_ratio, :erlang.float_to_binary(100 * &1.inadmissibles / (&1.admissibles + &1.inadmissibles), [decimals: 2])))).()
        |> (&(Map.put(&1, :submitted_ratio, :erlang.float_to_binary(100 * &1.submitted / (&1.total), [decimals: 2])))).()


      p ".text-center Citation du jour:"
      h1 "La Team Avril, elle est pas fragile !"
      hr
      div ".section" do
        h2 "Candidatures"
        ul do
          li "#{applications.total} candidatures"
          li "#{applications.submitted} soumises (#{applications.submitted_ratio}%)"
          li "#{applications.admissibles} admissibles (#{applications.admissibles_ratio}%)"
          li "#{applications.inadmissibles} rejetées (#{applications.inadmissibles_ratio}%)"
        end
        div "#applications-plot.plot-container" do
          pre do
            Poison.encode!(%{
              unknown: applications.unknown_week_array,
              submitted: applications.submitted_week_array,
              admissible: applications.admissible_week_array,
              inadmissible: applications.inadmissible_week_array
            }, pretty: true)
          end
          div ".plot"
        end
      end
    end
  end
end
