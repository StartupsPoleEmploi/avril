defmodule Mix.Tasks.UpdateCertifications do
  require Logger
  use Mix.Task
  import Mix.Ecto
  import Ecto.Query
  import SweetXml
  alias Vae.Repo

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:poison)
    {:ok, _started} = Application.ensure_all_started(:hackney)
    restore_with_certifier()
    parse()
  end

  @discard ~w(
    ID
    FICHE
    ETAT_FICHE
    CODES_NSF
    CERTIFICATEUR
    SECTEUR_ACTIVITE
    TYPE_EMPLOI_ACCESSIBLES
    CODES_ROME
    REGLEMENTATIONS_ACTIVITES
    SI_JURY_FI
    JURY_FI
    SI_JURY_CA
    JURY_CA
    SI_JURY_FC
    JURY_FC
    SI_JURY_CQ
    JURY_CQ
    SI_JURY_CL
    JURY_CL
    SI_JURY_VAE
    JURY_VAE
    ACCESSIBLE_NOUVELLE_CALEDONIE
    ACCESSIBLE_POLYNESIE_FRANCAISE
    PUBLICATION_DECRET_GENERAL
    REFERENCE_DECRET_CREATION
    PUBLICATION_DECRET_CREATION
    DATE_DERNIER_JO
    LIEN_STATIQUES
    DATE_FIN_ENREGISTREMENT)a

  def restore_with_certifier() do
    Repo.all(from c in Vae.Certification, where: is_nil(c.rncp_id))
    |> Repo.preload(:certifiers)
    |> Enum.map(fn c ->
      if length(c.certifiers) == 1 && String.starts_with?(List.first(c.certifiers).name, "RNCP ") do
        match = Regex.named_captures(~r/RNCP (?<rncp_id>\d+)/, List.first(c.certifiers).name)
        rncp_id = if match, do: match["rncp_id"]
        certification_id = c.id
        select_query = from cq in Vae.Certification, where: [id: ^certification_id]
        Repo.update_all(select_query, set: [rncp_id: rncp_id])
      end
    end)
  end


  def parse() do
    # {:ok, :saved_to_file} = :httpc.request(:get, {'https://elixir-lang.org/images/logo/logo.png', []}, [], [stream: "priv/rncp_2019_11.xml"])

    File.stream!("priv/rncp_2019_11.xml")
    |> SweetXml.stream_tags(:FICHE, discard: @discard)
    |> Stream.map(fn {_foo, doc} ->
      SweetXml.xmap(
        doc,
        label: ~x"./INTITULE/text()"s,
        acronym: ~x"./ABREGE/CODE/text()"s,
        activities: ~x"./ACTIVITES_VISEES/text()"s,
        abilities: ~x"./CAPACITES_ATTESTEES/text()"s,
        skills: [
          ~x"//BLOCS_COMPETENCES/BLOC_COMPETENCES"l,
          code: ~x"./CODE/text()"s,
          label: ~x"./LIBELLE/text()"s
        ],
        rncp_id:
          ~x"./NUMERO_FICHE/text()"s
          |> transform_by(fn s -> String.slice(s, 4..String.length(s)) end)
      )
    end)
    |> Stream.filter(fn certification ->
      # Logger.info("Rncp id not found for #{certification.label}")s
      !Vae.String.is_blank?(certification.rncp_id) && !Vae.String.is_blank?(certification.label)
    end)
    |> Stream.scan(%{ok: [], errors: []}, fn c, acc ->
      case retrieve_certification(c) do
        nil ->
          acc
        certification ->
          [
            certification
            |> Ecto.Changeset.change(
              label: c.label,
              acronym: c.acronym,
              description: "#{get_text(c.activities)} #{get_text(c.abilities)}}",
              rncp_id: c.rncp_id
            )
            |> Repo.update!()
            | acc
          ]
      end
    end)
    |> Enum.to_list()
  end

  defp retrieve_certification(certification) do
    Repo.get_by(Vae.Certification, rncp_id: certification.rncp_id) ||
      try do
        Repo.get_by(Vae.Certification, slug: to_slug(certification))
      rescue
        Ecto.MultipleResultsError ->
          merge_certifications(certification)
          retrieve_certification(certification)
      end
  end

  defp merge_certifications(certification) do
    slug = to_slug(certification)
    query = from c in Vae.Certification, where: c.slug == ^slug

    certification_ids = Repo.all(query)
    |> IO.inspect()
    |> Enum.map(&(Map.get(&1, :id)))

    keep_certification_id = Mix.Shell.IO.prompt("Laquelle faut-il conserver ? \nRéponses possibles: #{certification_ids |> Enum.join(", ")}\n")
    |> String.trim()
    |> String.to_integer()

    remove_certification_ids = certification_ids |> Enum.reject(fn id -> id == keep_certification_id end)

    IO.puts("Nous allons supprimer les certifications #{remove_certification_ids |> Enum.join(", ")}")

    if Enum.member?(certification_ids, keep_certification_id) do

      applications_to_update_query = from a in Vae.Application, where: a.certification_id in ^remove_certification_ids
      {nb_updated, _} = Repo.update_all(applications_to_update_query, set: [certification_id: keep_certification_id])
      IO.puts("#{nb_updated} candidatures mises à jour.")

      certification_delegates_to_update_query = from cd in Vae.CertificationDelegate, where: cd.certification_id in ^remove_certification_ids
      {nb_updated, _} = Repo.update_all(certification_delegates_to_update_query, set: [certification_id: keep_certification_id])
      IO.puts("#{nb_updated} relation certification delegate mises à jour.")

      # Can't be done with ecto :( as I cant't select and update the certifiers with the many to many association
      Enum.map(remove_certification_ids, fn id ->
        certifier_ids = Vae.Repo.get(Vae.Certification, id) |> Vae.Repo.preload(:certifiers) |> Map.get(:certifiers) |> Enum.map(&(&1.id))
        if length(certifier_ids) > 0 do
          result = Ecto.Adapters.SQL.query!(
            Vae.Repo, "UPDATE certifier_certifications SET certification_id=$1 WHERE certifier_id IN (#{certifier_ids |> Enum.join(", ")})", [keep_certification_id]
          )
          IO.puts("#{result.num_rows} certifier_certifications mises à jour")
        end
        rome_ids = Vae.Repo.get(Vae.Certification, id) |> Vae.Repo.preload(:romes) |> Map.get(:romes) |> Enum.map(&(&1.id))
        if length(rome_ids) > 0 do
          result = Ecto.Adapters.SQL.query!(
            Vae.Repo, "UPDATE rome_certifications SET certification_id=$1 WHERE rome_id IN (#{rome_ids |> Enum.join(", ")})", [keep_certification_id]
          )
          IO.puts("#{result.num_rows} rome_certifications mises à jour")
        end
      end)

      certifications_to_remove_query = from c in Vae.Certification, where: c.id in ^remove_certification_ids

      {nb_deleted, _} = Repo.delete_all(certifications_to_remove_query)
      IO.puts("#{nb_deleted} certifications supprimées.")

      # removed_certifications = Repo.all(certifications_to_remove_query)
      # |> Enum.map(fn c -> Repo.delete(c) end)
      # IO.puts("#{length(removed_certifications)} certifications supprimées.")
    else
      IO.puts("Réponse impossible, on arrête tout.")
      exit(1)
    end

  end

  defp get_text(text) do
    text
    |> String.replace("\n", "")
    |> String.replace("<b>", "")
    |> String.replace("</b>", "")
    |> String.replace("<i>", "")
    |> String.replace("</i>", "")
  end

  defp to_slug(certification) do
    "#{certification.acronym} #{certification.label}"
    |> Vae.String.parameterize()
  end
end