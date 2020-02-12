defmodule Mix.Tasks.Certification.AddMissingCertifications do
  use Mix.Task

  import Ecto.Query

  alias Vae.Repo
  alias Vae.Certification
  alias Vae.Delegate
  alias Vae.Rome

  def run(_args) do
    delegates = Delegate |> where(certifier_id: 4) |> Repo.all()
    File.stream!("/priv/fixtures/csv/certifications_to_remove.csv")
    |> CSV.decode!(headers: true, num_workers: 1)
    |> Enum.each(fn %{
                      "Code RNCP" => rncp_code,
                      "Code rome" => romes,
                      "Intitulé" => label,
                      "Niveau" => level
                    } ->
      cond do
        Certification |> where(label: ^label, acronym: "TP") |> Repo.one() == nil ->
          %Certification{
            label: label,
            acronym: "TP",
            level: level |> map_level,
            rncp_id: rncp_code
          }
          |> Repo.insert!()
          |> Repo.preload([:romes, :delegates])
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(
            :romes,
            romes |> String.split() |> Enum.map(&Repo.get_by!(Rome, code: &1))
          )
          |> Ecto.Changeset.put_assoc(:delegates, delegates)
          |> Repo.update!()

        true ->
          true
      end
    end)
  end

  defp map_level(level) do
    case level do
      "I" -> 1
      "II" -> 2
      "III" -> 3
      "IV" -> 4
      "V" -> 5
      _ -> 6
    end
  end
end
