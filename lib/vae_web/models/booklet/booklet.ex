defmodule Vae.Booklet do
  alias Vae.Booklet.{Cerfa, Experience}

  def from_application(application) do
    user = application.user

    %Cerfa{
      completed_at: nil,
      # certification_name: Certification.name(application.certification),
      # certifier_name: UserApplication.certifier_name(application),
      # civility: user.identity,
      experiences: user.proven_experiences |> group_experiences() |> map_experiences()
    }
  end

  def map_gender("male"), do: "m"
  def map_gender("female"), do: "f"
  def map_gender(_other), do: "o"

  def group_experiences([]), do: []

  def group_experiences(experiences) do
    Enum.group_by(experiences, fn experience ->
      [experience.company_name, experience.label, experience.contract_type]
    end)
  end

  def map_experiences([]), do: []

  def map_experiences(experiences) do
    Enum.map(experiences, fn {[_company_name, _label, _contract], data} ->
      merge_periods_into_experience(data, %Experience{})
    end)
  end

  def merge_periods_into_experience([], acc), do: acc

  def merge_periods_into_experience([h | t], acc) do
    # This could be removed if data is migrated to change 01/01/4000 end dates to nil
    # CF. proven_experiences.ex
    end_date = if h.end_date && Date.compare(Timex.today(), h.end_date) == :gt, do: h.end_date

    merge_periods_into_experience(
      t,
      %Experience{
        acc
        | title: h.label,
          company_name: h.company_name,
          full_address: nil,
          employment_type: map_contract_type_from_string(h.contract_type),
          periods: [
            %Experience.Period{
              start_date: h.start_date,
              end_date: end_date,
              total_hours: h.work_duration
            }
            | acc.periods
          ]
      }
    )
  end

  def map_contract_type_from_string(status) do
    case status do
      s when s in ["CDI", "CDD", "CTT"] -> 1
      "CUI" -> 10
      "Professionnalisation" -> 9
      "Apprentissage" -> 8
      _ -> 1
    end
  end
end
