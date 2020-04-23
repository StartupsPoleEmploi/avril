defmodule Vae.PoleEmploi.Mappers.ProvenExperiencesMapper do
  def map(experiences) do
    %{
      proven_experiences:
        Enum.map(
          clean_proven_experiences(experiences),
          &to_proven_experience/1
        )
    }
  end

  # Always update ?
  def is_data_missing(_map), do: true

  defp clean_experiences(experiences) do
    experiences
    |> Enum.flat_map(fn %OAuth2.Response{body: %{"contrats" => contracts}} ->
      contracts
    end)
    |> Enum.uniq_by(fn contract -> contract["dateDebut"] end)
  end

  defp to_proven_experience(body) do
    %{
      start_date: Vae.Date.format(body["dateDebut"]),
      end_date: Vae.Date.format(body["dateFin"]),
      duration: body["dureeContrat"],
      label: Vae.String.titleize(body["intitulePoste"]),
      contract_type: body["natureContrat"],
      is_manager: body["niveauQualification"] == "Cadre",
      work_duration: body["quantiteTravail"],
      company_ape: body["entreprise"]["codeApe"],
      company_name: Vae.String.titleize(body["entreprise"]["nom"]),
      company_category: body["entreprise"]["regime"],
      company_state_owned: body["entreprise"]["secteur"] == "Public",
      company_uid: body["entreprise"]["siret"]
    }
  end
end
