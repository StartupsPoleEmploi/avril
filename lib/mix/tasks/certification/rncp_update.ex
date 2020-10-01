defmodule Mix.Tasks.RncpUpdate do
  require Logger
  use Mix.Task

  import SweetXml
  import Ecto.Query

  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}

  @cities ~w(
    angers
    avignon
    besancon
    bordeaux
    caen
    cergy
    creteil
    evry
    lille
    limoges
    lorraine
    lyon
    marseille
    montpellier
    nantes
    nice
    nimes
    normandie
    orleans
    paris
    pau
    perpignan
    poitiers
    rennes
    rouen
    strasbourg
    toulon
    toulouse
    tours
  )

  @roman_numbers %{
    "i" => "1",
    "ii" => "2",
    "iii" => "3",
    "iv" => "4",
    "v" => "5",
    "vi" => "6",
    "vii" => "7",
    "viii" => "8",
    "ix" => "9",
    "x" => "10",
    "xi" => "11",
    "xii" => "12",
    "xiii" => "13",
    "xiv" => "14",
    "xv" => "15"
  }

  @new_certifiers [
    "Ministère de l'intérieur",
    "Ministère de la transition écologique et solidarité",
    "Ministère de l'agriculture et de la pêche"
  ]

  @overrides %{
    "Conservatoire national des arts et métiers (CNAM)" => "CNAM",
    "MINISTERE DE L'EDUCATION NATIONALE ET DE LA JEUNESSE" => "Ministère de l'Education Nationale",
    "MINISTERE CHARGE DES AFFAIRES SOCIALES" => "Ministère des affaires sociales et de la santé",
    "Ministère chargé de l'Emploi" => "Ministère du travail",
    "Ministère du Travail - Délégation Générale à l'Emploi et à la Formation Professionnelle (DGEFP)" => "Ministère du travail",
    "Ministère chargé de l'enseignement supérieur" => "Ministère de l'Education Nationale",
    "Ministère chargé des sports et de la jeunesse" => "Ministère de la jeunesse, des sports et de la cohésion sociale",
    "Ministère de l'Education nationale et de la jeunesse" => "Ministère de l'Education Nationale",
    "Ministère de l'Enseignement Supérieur" => "Ministère de l'Education Nationale",
    "Ministère de la Défense" => "Ministère des Armées",
  }

  @log_file "priv/matches.log"

  def run([]) do
    Logger.error("RNCP filname argument required. Ex: mix RncpUpdate -f priv/rncp-2020-08-03.xml")
  end

  def run(args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    {options, [], []} = OptionParser.parse(args, aliases: [i: :interactive, f: :filename], strict: [filename: :string, interactive: :boolean])

    Logger.info("Start update RNCP with #{options[:filename]}")
    prepare_avril_data()

    build_and_transform_stream(
      options[:filename],
      &fiche_to_certification(&1)
    )

    build_and_transform_stream(
      options[:filename],
      &move_applications_if_inactive_and_set_newer_certification(&1, [interactive: options[:interactive]])
    )

    clean_avril_data()
  end


  defp prepare_avril_data() do
    Logger.info("Remove previous log file")
    :ok = File.rm(@log_file)

    Logger.info("Update slugs")
    Enum.each([Certifier, Delegate], fn klass ->
      Repo.all(klass)
      |> Enum.each(fn %klass{} = c ->
        klass.changeset(c) |> Repo.update()
      end)
    end)

    Logger.info("Make all certifications inactive")
    Repo.update_all(Certification, set: [is_active: false])

    Logger.info("Create static certifiers")
    Enum.each(@new_certifiers, fn c ->
      Repo.get_by(Certifier, slug: Vae.String.parameterize(c)) || create_certifier_and_maybe_delegate(c)
    end)
  end

  defp clean_avril_data() do
    # Remove certifiers without certifications
    from(c in Certifier,
      left_join: a in assoc(c, :certifications),
      left_join: d in assoc(c, :delegates),
      group_by: c.id,
      having: count(a.id) == ^0 and count(d.id) == ^0
    )
    |> Repo.all()
    |> Enum.each(fn c -> Repo.delete(c) end)
  end

  defp build_and_transform_stream(filename, transform) do
    File.stream!(filename)
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

  defp certifier_rncp_override(name) do
    case Enum.find(@overrides, fn {k, v} ->
      String.starts_with?(Vae.String.parameterize(name), Vae.String.parameterize(k))
    end) do
      {_k, val} -> val
      nil -> name
    end
  end

  defp match_or_build_certifier(name) do
    name_with_overrides = name
    |> certifier_rncp_override()
    |> prettify_name()

    slug = Vae.String.parameterize(name_with_overrides)

    case find_by_slug_or_closer_distance_match(Certifier, slug) do
      %Certifier{} = c -> c
      nil ->
        if String.contains?(slug, "universite") || String.contains?(slug, "ministere") do
          create_certifier_and_maybe_delegate(name_with_overrides)
        end
    end
  end

  defp create_certifier_and_maybe_delegate(name) do
    delegate = find_by_slug_or_closer_distance_match(Delegate, Vae.String.parameterize(name)) ||
      Delegate.changeset(%Delegate{}, %{
        name: name,
        is_active: false
      }) |> Repo.insert!()
    %Certifier{}
    |> Certifier.changeset(%{
      name: name,
      delegates: [delegate]
    })
    |> Repo.insert!()
  end

  defp find_by_slug_or_closer_distance_match(klass, slug, tolerance \\ 0.95) do
    case Repo.get_by(klass, slug: slug) do
      nil ->
        all_elements = Repo.all(klass)
        best_match = Enum.max_by(all_elements, &wordify_jaro_distance(slug, &1.slug))
        best_match_distance = wordify_jaro_distance(slug, best_match.slug)

        if best_match_distance > tolerance do
          log_into_file("""
            ####### MATCH #######
            Class: #{klass}
            Input: #{slug}
            Found: #{best_match.slug}
            Score: #{best_match_distance}
            #####################
          """)
          best_match
        end
      el -> el
    end
  end

  defp log_into_file(content) do
    {:ok, file} = File.open(@log_file, [:append])
    IO.write(file, content)
    :ok = File.close(file)
  end

  defp prettify_name(name) do
    name
    |> Vae.String.wordify()
    |> Enum.with_index()
    |> Enum.map(fn {word, i} ->
      case word do
        "UNIVERSITE" -> "Université"
        "MINISTERE" -> "Ministère"
        "DEFENSE" -> "Défense"
        "L'INTERIEUR" -> "l'intérieur"
        <<"(" :: utf8, _r :: binary>> = w -> w
        w ->
          if (i == 0 || Enum.member?(@cities, Vae.String.parameterize(w))) do
            String.capitalize(w)
          else
            String.downcase(w)
          end
      end
    end)
    |> Enum.map(&replace_roman_numbers(&1))
    |> Enum.join(" ")
  end

  defp replace_roman_numbers(word) do
    @roman_numbers[String.downcase(word)] || word
  end

  def wordify_jaro_distance(string1, string2) do
    [short | [long | rest]] = [wordify(string1), wordify(string2)]
    |> Enum.sort_by(&(length(&1)))

    short
    |> Enum.map(fn word1 ->
      long
      |> Enum.map(fn word2 ->
        cond do
          Integer.parse(word1) !== :error && Integer.parse(word2) !== :error ->
            (if word1 == word2, do: 1, else: 0)
          Enum.member?(@cities, word1) ->
            (if word1 == word2, do: 1, else: 0)
          true ->
            String.jaro_distance(word1, word2)
        end
      end)
      |> Enum.max()
    end)
    |> (fn d -> Enum.sum(d)/length(d) end).()
  end

  defp wordify(string1) do
    string1
    |> Vae.String.parameterize()
    |> String.split("-")
    |> Enum.filter(fn w -> Enum.member?(~w(de la )) end)
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
          Logger.warn(inspect(e))
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
