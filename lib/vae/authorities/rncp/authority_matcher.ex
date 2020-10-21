defmodule Vae.Authorities.Rncp.AuthorityMatcher do
  require Logger
  alias Vae.Repo
  alias Vae.Authorities.Rncp.FileLogger

  @ignored_words ~w(de du la le d des et)
  @pre_capitalization ~w(d' l')
  @middle_capitalization ~w(( -)

  @cities ~w(
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
    cambresis
    cezanne
    champagne-ardenne
    charles
    claude
    compiègne
    corse
    dauphine
    denis
    descartes
    eiffel
    essonne
    est
    etienne
    france
    franche-comte
    francois
    gaulle
    guyane
    gustave
    hainaut
    jaures
    jean
    jules
    loire
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
      "conservatoire-national-des-arts-et-metiers-cnam"
    ],
    "ministere-de-l-education-nationale" => [
      "ministere-de-l-education-nationale-et-de-la-jeunesse"
    ],
    "ministere-des-affaires-sociales-et-de-la-sante" => [
      "ministere-charge-des-affaires-sociales"
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
    "universite-paris-est-creteil" => [
      "upec",
      "universite-paris-12"
    ],
    "universite-paris-est-marne-la-vallee-upem" => [
      "universite-gustave-eiffel"
    ],
    "universite-paris-nanterre" => [
      "upl",
      "universite-paris-lumiere"
    ],
    "universite-de-paris-8-vincennes" => [
      "universite-paris-nord-sorbonne",
      "universite-paris-13",
      "universite-paris-8",
      "universite-paris-8-vincennes-st-denis"
    ],
    "universite-pierre-et-marie-curie-paris-6" => [
      "universite-sorbonne-nouvelle",
      "paris-sorbonne-paris-4",
      "upms-paris-6"
    ],
    "universite-de-paris" => [
      "universite-paris-7",
      "universite-paris-descartes-paris-5",
      "universite-de-paris-5-rene-descartes",
      "universite-paris-diderot"
    ]
  }

  def slug_with_aliases(slug) do
    case @aliases |> Enum.find(fn k, v -> AuthorityMatcher.find_by_custom_jaro_distance(v, slug, 0.98) end) do
      {actual_slug, alias_slug} -> actual_slug
      _ -> slug
    end
  end

  def find_by_slug_or_closer_distance_match(klass, name, tolerance) do
    slug = name
    |> Vae.String.parameterize()
    |> slug_with_aliases()

    Repo.get_by(klass, slug: slug) ||
      (if tolerance < 1, do: find_by_custom_jaro_distance(Repo.all(klass), slug, tolerance || 0.95, &(&1.slug)))
  end

  def find_by_custom_jaro_distance(list, string, tolerance \\ 0.95, map_fn \\ &(&1)) do
    {best_match, best_distance} = list
      |> Enum.reduce({nil, 0}, fn el, {_best, best_distance} = res ->
        case custom_jaro_distance(map_fn.(el), string) do
          distance when distance > best_distance -> {el, distance}
          _ -> res
        end
      end)

    if best_distance > tolerance do
      klass = case List.first(list) do
        %struct{} -> struct
        v when is_binary(v) -> "string"
        _ -> "unknown"
      end
      FileLogger.log_into_file("""
        ####### MATCH #######
        Class: #{klass}
        Input: #{string}
        Found: #{map_fn.(best_match)}
        Score: #{best_distance}
        #####################
      """)
      best_match
    end
  end

  def custom_jaro_distance(string1, string2) do
    [short | [long | _rest]] =
      [wordify(string1), wordify(string2)]
      |> Enum.sort_by(&(length(&1)))

    short
    |> Enum.map(fn word1 ->
      long
      |> Enum.map(&custom_word_distance(word1, &1))
      |> Enum.max()
    end)
    |> (fn d ->
      case d do
        [] -> 0
        d -> Enum.sum(d)/length(d)
      end
    end).()
  end

  defp custom_word_distance(word1, word2) do
    cond do
      Integer.parse(word1) !== :error && Integer.parse(word2) !== :error ->
        (if word1 == word2, do: 1, else: 0)
      Enum.member?(@cities, word1) ->
        (if word1 == word2, do: 1, else: 0)
      true ->
        String.jaro_distance(word1, word2)
    end
  end

  defp wordify(string1) do
    string1
    |> Vae.String.parameterize()
    |> String.split("-")
    |> Enum.filter(fn w -> !Enum.member?(@ignored_words, w) end)
    |> Enum.filter(&Vae.String.is_present?(&1))
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