defmodule Mix.Tasks.UpdateCertifications do
  require Logger
  use Mix.Task
  import Ecto.Query
  import SweetXml
  alias Vae.Repo

  def run(_args) do
    # ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:poison)
    {:ok, _started} = Application.ensure_all_started(:hackney)

    restore_with_csv_backup()
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

  def restore_with_csv_backup() do
    File.stream!("priv/armee-id-rncp.csv", [:utf8])
    |> CSV.decode!(headers: true, num_workers: 1, separator: ?;, strip_fields: true)
    |> Enum.each(fn %{
                      "label" => label,
                      "rncp_id" => rncp_id
                    } ->
      certification = smart_find_by_slug(to_slug("Diplôme Ministère des Armées", label))

      if certification do
        if certification.rncp_id && certification.rncp_id != rncp_id do
          Logger.warn("Different RNCP ID: #{certification.rncp_id} et #{rncp_id}")
        end

        Ecto.Changeset.change(certification, %{rncp_id: rncp_id}) |> Repo.update!()
      else
        Logger.warn("No certification found for label #{label}")
      end
    end)
  end

  def restore_with_certifier() do
    Repo.all(from(c in Vae.Certification, where: is_nil(c.rncp_id)))
    |> Repo.preload(:certifiers)
    |> Enum.each(fn c ->
      Enum.each(c.certifiers, fn cfier ->
        match = Regex.named_captures(~r/RNCP (?<rncp_id>\d+)/, cfier.name)

        if match && match["rncp_id"] do
          select_query = from(cq in Vae.Certification, where: [id: ^c.id])
          Repo.update_all(select_query, set: [rncp_id: match["rncp_id"]])
        end
      end)
    end)
  end

  def parse() do
    # System.cmd("rm", ["priv/rncp_2019_11.xml"]) |> IO.inspect()

    # System.cmd("curl", [
    #  "-o",
    #  "priv/rncp_2019_11.xml",
    #  "https://avril-resumes.s3.eu-west-3.amazonaws.com/rncp_2019_11.xml"
    # ])
    # |> IO.inspect()

    # IO.puts("RNCP xml file downloaded")

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
        smart_find_by_slug(to_slug(certification))
      rescue
        Ecto.MultipleResultsError ->
          merge_certifications(certification)
          retrieve_certification(certification)
      end
  end

  defp merge_certifications(certification) do
    slug = to_slug(certification)
    query = from(c in Vae.Certification, where: c.slug == ^slug)

    certification_ids =
      Repo.all(query)
      |> Enum.map(&Map.get(&1, :id))

    keep_certification_id = Enum.min(certification_ids)

    remove_certification_ids =
      certification_ids |> Enum.reject(fn id -> id == keep_certification_id end)

    if Enum.member?(certification_ids, keep_certification_id) do
      # This is the clean way to merge associations
      applications_to_update_query =
        from(a in Vae.Application, where: a.certification_id in ^remove_certification_ids)

      {nb_updated, _} =
        Repo.update_all(applications_to_update_query,
          set: [certification_id: keep_certification_id]
        )

      IO.puts("#{nb_updated} candidatures mises à jour.")

      # Unfortunately it is not simple with many_to_many associations, hence custom SQL queries. Also, unicity constraint needs to be checked
      Enum.each(remove_certification_ids, fn remove_certification_id ->
        association_remove_dups_and_update_others(
          keep_certification_id,
          remove_certification_id,
          :certifiers,
          "certifier_certifications"
        )

        association_remove_dups_and_update_others(
          keep_certification_id,
          remove_certification_id,
          :romes,
          "rome_certifications"
        )

        association_remove_dups_and_update_others(
          keep_certification_id,
          remove_certification_id,
          :delegates,
          "certifications_delegates"
        )
      end)

      certifications_to_remove_query =
        from(c in Vae.Certification, where: c.id in ^remove_certification_ids)

      {nb_deleted, _} = Repo.delete_all(certifications_to_remove_query)
      IO.puts("#{nb_deleted} certifications supprimées.")
    else
      IO.puts("Réponse impossible, on arrête tout.")
      exit(1)
    end
  end

  def association_remove_dups_and_update_others(
        keep_certification_id,
        remove_certification_id,
        association,
        table_name
      ) do
    keep_certification_association_ids =
      Vae.Repo.get(Vae.Certification, keep_certification_id)
      |> Vae.Repo.preload(association)
      |> Map.get(association)
      |> Enum.map(& &1.id)

    remove_certification_association_ids =
      Vae.Repo.get(Vae.Certification, remove_certification_id)
      |> Vae.Repo.preload(association)
      |> Map.get(association)
      |> Enum.map(& &1.id)

    update_association_ids =
      remove_certification_association_ids -- keep_certification_association_ids

    remove_association_ids = remove_certification_association_ids -- update_association_ids

    if length(update_association_ids) > 0 do
      result =
        Ecto.Adapters.SQL.query!(
          Vae.Repo,
          "UPDATE #{table_name} SET certification_id=$1 WHERE certification_id=$2 AND #{
            association |> Inflex.singularize()
          }_id IN (#{update_association_ids |> Enum.join(", ")})",
          [keep_certification_id, remove_certification_id]
        )

      IO.puts("#{result.num_rows} #{table_name} mises à jour")
    end

    if length(remove_association_ids) > 0 do
      result =
        Ecto.Adapters.SQL.query!(
          Vae.Repo,
          "DELETE FROM #{table_name} WHERE certification_id=$1 AND #{
            association |> Inflex.singularize()
          }_id IN (#{remove_association_ids |> Enum.join(", ")})",
          [remove_certification_id]
        )

      IO.puts("#{result.num_rows} #{table_name} supprimées")
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
    to_slug(certification.acronym, certification.label)
  end

  defp to_slug(acronym, label) do
    Vae.String.parameterize("#{acronym} #{label}")
  end

  def slug_words(slug) do
    slug |> String.split("-") |> Enum.filter(&(String.length(&1) > 2))
  end

  def smart_find_by_slug(slug) do
    Repo.get_by(Vae.Certification, slug: slug) ||
      (
        words = slug_words(slug)

        wheres =
          Enum.reduce(words, true, fn word, query ->
            dynamic([c], like(c.slug, ^"%#{word}%") and ^query)
          end)

        query = from(c in Vae.Certification, where: ^wheres)
        results = Vae.Repo.all(query)

        if length(results) > 1 do
          Logger.info(
            "Plusieurs résultats pour \n#{slug}:\n#{
              Enum.map(results, & &1.slug) |> Enum.join("\n")
            }"
          )
        end

        winner = closest_slug(slug, results)
        Logger.info("Le gagnant est : #{winner && winner.slug}")
        winner
      )
  end

  def closest_slug(slug, results) do
    Enum.sort_by(results, fn result ->
      1 - String.jaro_distance(slug, result.slug)
    end)
    |> List.first()
  end
end
