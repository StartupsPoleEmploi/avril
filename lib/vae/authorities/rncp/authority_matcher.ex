defmodule Vae.Authorities.Rncp.AuthorityMatcher do
  require Logger
  alias Vae.{Certifier, Repo}
  alias Vae.Authorities.Rncp.FileLogger

  @ignored_words ~w(de du la le d des et en)
  @pre_capitalization ~w(d' l')
  @middle_capitalization ~w(( -)

  @ignored_certifier_slugs ~w(
    universite-de-nouvelle-caledonie
    universite-de-la-nouvelle-caledonie
    universite-de-la-polynesie-francaise
    sncf-universite-de-la-surete
    universite-du-vin
    universite-scienchumaines-lettres-arts
    universite-de-technologie-belfort-montbeliard
    universite-catholique-de-l-ouest
    centre-universitaire-des-sciences-et-techniques-de-l-universite-clermont-ferrand
    universite-europeenne-des-senteurs-et-des-saveurs
    languedoc-roussillon-universites
  )

  @cities ~w(
    aix
    amiens
    angers
    avignon
    belfort-montbeliard
    besancon
    bordeaux
    brest
    caen
    cergy
    cergy-pontoise
    chambery
    clermont-ferrand
    compiègne
    creteil
    dijon
    evry
    grenoble
    havre
    lille
    limoges
    lorraine
    lyon
    mans
    marne-la-vallee
    marseille
    montpellier
    mulhouse
    nanterre
    nantes
    nice
    nimes
    orleans
    paris
    pau
    perpignan
    poitiers
    reims
    rennes
    rouen
    saint-etienne
    saint-denis
    saint-quentin-en-yvelines
    strasbourg
    toulon
    toulouse
    tours
    valenciennes
    versailles
    vincennes
  )

  @other_capitalize_nouns ~w(
    adour
    alpes
    alsace
    antilles
    antipolis
    ardenne
    artois
    auvergne
    bernard
    blaise
    bourgogne
    bretagne
    caledonie
    cezanne
    champagne-ardenne
    charles
    claude
    compiegne
    corse
    dauphine
    denis
    descartes
    eiffel
    essonne
    est
    etienne
    evry-val-d-essonne
    france
    franche-comte
    francois
    gaulle
    guyane
    gustave
    hainaut-cambresis
    jaures
    jean
    jules
    loire
    maine
    mediterranee
    monnet
    montaigne
    moulin
    nord
    normandie
    nouvelle-caledonie
    ouest
    paul
    panthéon
    pascal
    pasquale
    paoli
    paris-dauphine
    paris-est
    picardie
    pontoise
    provence
    quentin
    rabelais
    reunion
    rene
    rochelle
    roussillon
    sabatier
    saclay
    saint
    savoie
    segalen
    sophia
    sorbonne
    sud
    universite
    var
    valery
    val-de-marne
    verne
    victor
    yveline
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

  @aliases %{
    "cnam" => [
      "conservatoire-national-des-arts-et-metiers-cnam",
      "conservatoire-national-des-arts-et-metiers"
    ],
    "ministere-de-l-education-nationale" => [
      "ministere-de-l-education-nationale-et-de-la-jeunesse"
    ],
    "ministere-des-affaires-sociales-et-de-la-sante" => [
      "ministere-charge-des-affaires-sociales",
      "ministere-charge-de-la-sante"
    ],
    "ministere-du-travail" => [
      "ministere-charge-de-l-emploi",
      "ministere-du-travail-delegation-generale-a-l-emploi-et-a-la-formation-professionnelle-dgefp"
    ],
    "ministere-de-la-jeunesse-des-sports-et-de-la-cohesion-sociale" => [
      "ministere-charge-des-sports-et-de-la-jeunesse"
    ],
    "ministere-de-l-enseignement-superieur" => [
      "ministere-de-l-enseignement-superieur-de-la-recherche-et-de-l-innovation"
    ],
    "ministere-des-armees" => [
      "ministere-de-la-defense"
    ],
    "ministere-charge-de-l-agriculture" => [
      "ministere-de-l-agriculture-et-de-la-peche"
    ],
    "universite-paris-saclay" => [
      "communaute-d-universites-et-etablissements-universite-paris-saclay",
      "universite-paris-sud-paris-11",
      "universite-paris-sud",
      "universite-paris-11"
    ],
    "universite-de-corse-pasquale-paoli" => [
      "universite-de-corse-p-paoli"
    ],
    "universite-paris-est-creteil-val-de-marne" => [
      "upec",
      "universite-paris-12"
    ],
    "universite-paris-est-marne-la-vallee-upem" => [
      "universite-gustave-eiffel",
      "universite-paris-est-marne-la-vallee",
      "universite-paris-est",
      "universite-de-marne-la-vallee",
      "universite-de-marne-la-vallee-seine-et-marne"
    ],
    "universite-paris-nanterre" => [
      "universite-paris-ouest-nanterre-la-defense",
      "universite-paris-ouest-nanterre-la-defense-paris-10"
    ],
    "universite-paris-lumiere" => [
      "upl",
    ],
    "universite-de-paris-8-vincennes" => [
      "universite-de-paris-8-paris-vincenn",
      "universite-paris-8",
      "universite-paris-8-vincennes-st-denis",
      "universite-paris-xiii-nord-institut-universitaire-de-technologie-de-saint-denis"
    ],
    "universite-paris-13" => [
      "universite-paris-nord-sorbonne",
      "universite-villetaneuse"
      ],
    "universite-pierre-et-marie-curie-paris-6" => [
      "universite-sorbonne-nouvelle",
      "paris-sorbonne-paris-4",
      "upms-paris-6",
      "universite-paris-6-pierre-et-marie-curie",
      "universite-pierre-et-marie-curie-paris-paris-6-upmc"
    ],
    "universite-paris-1-pantheon-sorbonne" => [
      "universite-pantheon-sorbonne-paris-1",
      "universite-paris-1-pantheon-sorbonne",
      "universite-sorbonne-paris-cite"
    ],
    "universite-de-paris" => [
      "universite-paris-7",
      "universite-paris-descartes-paris-5",
      "universite-de-paris-5-rene-descartes",
      "universite-paris-diderot",
      "universite-paris-descartes-iut"
    ],
    "universite-de-cergy-pontoise" => [
      "cy-cergy-paris-universite",
      "universite-cergy-pontoise",
      "universite-paris-seine"
    ],
    "universite-psl-paris-sciences-lettres" => [
      "communaute-d-universites-et-etablissements-universite-de-recherche-paris-sciences-et-lettres-psl-research-university",
      "universite-psl"
    ],
    "universite-paris-2-pantheon-assas" => [
      "universite-pantheon-assas-paris-2",
      "universite-paris-2-pantheon-assas"
    ],
    "universite-paris-dauphine-psl" =>[
      "universite-paris-dauphine"
    ],
    "universite-cote-d-azur" => [
      "universite-de-nice",
      "universite-nice-sophia-antipolis"
    ],
    "universite-jean-jaures-toulouse-2" => [
      "universite-de-toulouse-jean-jaures"
    ]
  }

  def buildable_certifier?(name) do
    slug = Vae.String.parameterize(name)
    String.contains?(slug, "universite") &&
      not String.contains?(slug, "polytech") &&
      not Enum.member?(@ignored_certifier_slugs, slug)
  end

  def slug_with_aliases(slug) do
    case @aliases |> Enum.find(fn {k, v} -> (k == slug) || Enum.member?(v, slug) || find_by_custom_jaro_distance(v, slug, 1) end) do
      {actual_slug, _alias_slug} -> actual_slug
      _ -> slug
    end
  end

  def find_by_siret(%{siret: siret}) when not is_nil(siret) do
    Repo.get_by(Certifier, siret: siret)
  end
  def find_by_siret(_), do: nil

  def find_by_slug_or_closer_distance_match(klass, name, tolerance \\ nil) do
    tolerance = tolerance || 0.95
    slug = name
    |> Vae.String.parameterize()
    |> slug_with_aliases()

    mapper = if klass == Delegate, do: &(Vae.String.parameterize(&1.name)), else: &(&1.slug)

    Repo.get_by(klass, slug: slug) ||
      (if tolerance < 1, do: find_by_custom_jaro_distance(Repo.all(klass), slug, tolerance || 0.95, mapper))
  end

  def find_by_custom_jaro_distance(list, string, tolerance \\ 0.95, map_fn \\ &(&1)) do
    {best_match, best_distance} = list
      |> Enum.reduce({nil, 0}, fn el, {_best, best_distance} = res ->
        case custom_jaro_distance(map_fn.(el), string) do
          distance when distance > best_distance -> {el, distance}
          _ -> res
        end
      end)

    if best_distance >= tolerance do
      if string != map_fn.(best_match) do
        klass = case List.first(list) do
          %struct{} -> struct
          v when is_binary(v) -> "string"
          _ -> "unknown"
        end
        FileLogger.log_into_file("matches.csv", [klass, string, map_fn.(best_match), best_distance])
      end
      best_match
    end
  end

  def custom_jaro_distance(string1, string2) do
    [short | [long | _rest]] =
      [wordify(string1), wordify(string2)]
      |> Enum.sort_by(&(length(&1)))

    words_score = short
    |> Enum.map(fn word1 ->
      long
      |> Enum.map(&custom_word_distance(word1, &1))
      |> Enum.max()
    end)
    |> case do
      [] -> 0
      d -> Enum.sum(d)/length(d)
    end

    length_diff_penalty = abs(length(long) - length(short)) * 0.001

    words_score - length_diff_penalty
  end

  defp custom_word_distance(word1, word2) do
    cond do
      Integer.parse(word1) !== :error && Integer.parse(word2) !== :error ->
        (if word1 == word2, do: 1, else: 0)
      Enum.member?(@cities, word1) || Enum.member?(@cities, word2) ->
        (if word1 == word2, do: 1, else: 0)
      true ->
        String.jaro_distance(word1, word2)
    end
  end

  defp wordify(string1) do
    string1
    |> Vae.String.parameterize()
    |> String.split("-")
    |> Enum.reject(&Enum.member?(@ignored_words, &1))
    |> Enum.reject(&Vae.String.is_blank?(&1))
  end

  defp replace_roman_numbers(word) do
    @roman_numbers[String.downcase(word)] || word
  end

  def prettify_name(name) do
    name
    |> Vae.String.wordify()
    |> Enum.with_index()
    |> Enum.map(fn {word, i} ->
      case String.downcase(word) do
        "st" -> "Saint"
        "universite" -> "Université"
        "ministere" -> "Ministère"
        "defense" -> "Défense"
        "l'interieur" -> "l'intérieur"
        <<"(" :: utf8, _r :: binary>> = w -> w
        w ->
          if (i == 0 || is_special_word?(w) && not Enum.member?(@ignored_words, w)) do
            smarter_capitalize(w)
          else
            w
          end
      end
    end)
    |> Enum.map(&replace_roman_numbers(&1))
    |> Enum.join(" ")
  end

  def is_special_word?(w) do
    @cities ++ @other_capitalize_nouns
    |> Enum.join(" ")
    |> String.contains?(Vae.String.parameterize(remove_apostrophes(w)))
  end

  def smarter_capitalize(w) do
    Enum.reduce(@middle_capitalization, w, fn mc, res ->
      String.split(res, mc)
      |> Enum.map(&capitalize_ignore_apostrophes(&1))
      |> Enum.join(mc)
    end)
  end

  def capitalize_ignore_apostrophes(w) do
    case Enum.find(@pre_capitalization, &String.starts_with?(w, &1)) do
      nil -> String.capitalize(w)
      hd ->
        "#{hd}#{String.capitalize(String.replace_prefix(w, hd, ""))}"
    end
  end

  def remove_apostrophes(w) do
    case Enum.find(@pre_capitalization, &String.starts_with?(w, &1)) do
      nil -> w
      hd -> String.replace_prefix(w, hd, "")
    end
  end

end