defmodule Mix.Tasks.RncpUpdate do
  require Logger
  use Mix.Task

  import SweetXml
  import Ecto.Query

  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}

  @cities ~w(
    angers
    besancon
    caen
    lille
    lyon
    nantes
    nice
    nimes
    orleans
    paris
    rouen
    toulon
    toulouse
    tours
  )

  @overrides %{
    "Conservatoire national des arts et métiers (CNAM)" => "CNAM",
    "MINISTERE DE L'EDUCATION NATIONALE ET DE LA JEUNESSE" => "Ministère de l'Education Nationale",
    "Ministère chargé de l'Emploi" => "Ministère du travail",
    "Ministère chargé de l'enseignement supérieur" => "Ministère de l'Education Nationale",
    "Ministère chargé des sports et de la jeunesse" => "Ministère de la jeunesse, des sports et de la cohésion sociale",
    "Ministère de l'Education nationale et de la jeunesse" => "Ministère de l'Education Nationale",
    "Ministère de l'Enseignement Supérieur" => "Ministère de l'Education Nationale",
    "Ministère de la Défense" => "Ministère des Armées",
    "Université de Bourgogne - Dijon" => "Université de Bourgogne - pole VAE- SEFCA",
    "Université Lumière - Lyon 2" => "Université Lyon 2 Service Commun de Formation Continue",
    "Université Paul Valéry - Montpellier 3" => "Université Paul Valéry Montpellier 3",
  }

  def run(args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    {[filename: filename, interactive: interactive], [], []} = OptionParser.parse(args, aliases: [i: :interactive, f: :filename], strict: [filename: :string, interactive: :boolean])

    Logger.info("Start update RNCP with #{filename}")
    prepare_avril_data()

    build_and_transform_stream(
      filename,
      &fiche_to_certification(&1)
    )

    build_and_transform_stream(
      filename,
      &move_applications_if_inactive_and_set_newer_certification(&1, [interactive: interactive])
    )

    clean_avril_data()
  end

  def run(_args) do
    Logger.error("RNCP filname argument required. Ex: mix RncpUpdate -f rncp-2020-08-03.xml")
  end

  defp prepare_avril_data() do
    Logger.info("Update slugs")
    Enum.each([Certifier, Delegate], fn klass ->
      Repo.all(klass)
      |> Enum.each(fn %klass{} = c ->
        klass.changeset(c) |> Repo.update()
      end)
    end)

    Logger.info("Make all certifications inactive")
    Repo.update_all(Certification, set: [is_active: false])

  end

  defp clean_avril_data() do
    # Remove certifiers without certifications
    from(c in Certifier,
      left_join: a in assoc(c, :certifications),
      group_by: c.id,
      having: count(a.id) == ^0
    )
    |> Repo.all()
    |> Enum.each(fn c -> Repo.delete(c) end)
  end

  defp build_and_transform_stream(filename, transform) do
    File.stream!("priv/#{filename}")
    |> SweetXml.stream_tags(:FICHE)
    |> Stream.filter(fn {_, fiche} ->
      !String.starts_with?(xpath(fiche, ~x"./INTITULE/text()"s), "CQP")
    end)
    |> Stream.map(fn {_, fiche} -> transform.(fiche) end)
    |> Enum.to_list()
  end

  defp fiche_to_certification(fiche) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    Logger.info("Updating RNCP_ID: #{rncp_id}")

    romes = SweetXml.xpath(fiche, ~x"./CODES_ROME/ROME"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./CODE/text()"s) end)
      |> Enum.map(fn code -> Repo.get_by(Rome, code: code) end)

    certifiers = SweetXml.xpath(fiche, ~x"./CERTIFICATEURS/CERTIFICATEUR"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./NOM_CERTIFICATEUR/text()"s) end)
      |> Enum.map(&match_or_build_certifier/1)
      |> Enum.filter(&not(is_nil(&1)))
      |> Enum.uniq_by(&(&1.slug))

    SweetXml.xmap(fiche,
      label: ~x"./INTITULE/text()"s |> transform_by(&String.slice(&1, 0, 225)),
      acronym: ~x"./ABREGE/CODE/text()"s,
      activities: ~x"./ACTIVITES_VISEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      abilities: ~x"./CAPACITES_ATTESTEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      activity_area: ~x"./SECTEURS_ACTIVITE/text()"s,
      accessible_job_type: ~x"./TYPE_EMPLOI_ACCESSIBLES/text()"s,
      level: ~x"./NOMENCLATURE_EUROPE/NIVEAU/text()"s |> transform_by(fn l ->
        l
        |> String.replace_prefix("NIV", "")
        |> Vae.Maybe.if(&Vae.String.is_present?/1, &String.to_integer/1)
      end),
      is_active: ~x"./ACTIF/text()"s |> transform_by(fn t ->
        case t do
          "Oui" -> true
          _ -> false
        end
      end)
    )
    |> Map.merge(%{
      rncp_id: rncp_id,
      romes: romes,
      certifiers: certifiers
    })
    |> insert_or_update_by_rncp_id()
  end

  defp certifier_rncp_override(name), do: @overrides[name] || name

  defp match_or_build_certifier(name) do
    name_with_overrides = certifier_rncp_override(name)
    slug = Vae.String.parameterize(name_with_overrides)

    case find_by_slug_or_closer_distance_match(Certifier, slug) do
      %Certifier{} = c -> c
      nil ->
        if String.contains?(slug, "universite") || String.contains?(slug, "ministere") do
          delegate = find_by_slug_or_closer_distance_match(Delegate, slug) ||
            Delegate.changeset(%Delegate{}, %{
              name: name_with_overrides,
              is_active: false
            }) |> Repo.insert!()
          %Certifier{}
          |> Certifier.changeset(%{
            name: name_with_overrides,
            delegates: [delegate]
          })
          |> Repo.insert!()
        end
    end
  end

  defp find_by_slug_or_closer_distance_match(klass, slug, tolerance \\ 0.9) do
    case Repo.get_by(klass, slug: slug) do
      %klass{} = el -> el
      nil ->
        all_elements = Repo.all(klass)
        best_match = Enum.max_by(all_elements, &String.jaro_distance(slug, &1.slug))
        best_match_distance = String.jaro_distance(slug, best_match.slug)

        if best_match_distance > tolerance && city_names_match(best_match.slug, slug) do
          Logger.info("##### MATCH #######")
          Logger.info(klass)
          Logger.info(slug)
          Logger.info(best_match.slug)
          Logger.info(best_match_distance)
          Logger.info("###################")
          best_match
        end
    end
  end

  defp city_names_match(slug1, slug2) do
    cities1 = Enum.filter(@cities, fn c -> String.contains?(slug1, c) end)
    cities2 = Enum.filter(@cities, fn c -> String.contains?(slug2, c) end)
    cities1 -- cities2 == []
  end

  defp insert_or_update_by_rncp_id(%{rncp_id: rncp_id} = fields) do
    Repo.get_by(Certification, rncp_id: rncp_id)
    |> case do
      nil -> %Certification{rncp_id: rncp_id}
      %Certification{} = c -> c
    end
    |> Repo.preload([:certifiers, :romes])
    |> Certification.changeset(fields)
    |> Repo.insert_or_update()
  end

  defp move_applications_if_inactive_and_set_newer_certification(fiche, options) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    with(
      %Certification{id: certification_id, is_active: false} = certification <-
        Repo.get_by(Certification, rncp_id: rncp_id) |> Repo.preload([:newer_certification]),
      newer_rncp_id when not is_nil(newer_rncp_id) <-
        SweetXml.xpath(fiche, ~x"./NOUVELLE_CERTIFICATION/text()"s
          |> transform_by(fn nb ->
            String.replace_prefix(nb, "RNCP", "")
          end)),
      %Certification{id: newer_certification_id, is_active: true} = newer_certification <-
        Repo.get_by(Certification, rncp_id: newer_rncp_id),
      {:ok, _} <- Certification.changeset(certification, %{newer_certification: newer_certification}) |> Repo.update()
    ) do
      try do
        from(a in UserApplication,
          where: [certification_id: ^certification_id]
        ) |> Repo.update_all(set: [certification_id: newer_certification_id])
      rescue
        e in Postgrex.Error ->
          Logger.warn(e)
          if options[:interactive] do
            id = IO.gets("Quel ID supprime-t-on ? ")
            |> String.trim()
            |> String.to_integer()

            Repo.get(UserApplication, id) |> Repo.delete()
          else
            Logger.warn("Ignored. Run with -i option to make it interactive")
          end
      end
    end
  end
end
