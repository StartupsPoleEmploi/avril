defmodule Vae.Authorities.Rncp.AuthorityMatcher do
  require Logger
  alias Vae.Repo
  alias Vae.Authorities.Rncp.FileLogger

  @ignored_words ~w(de du la le d)
  @pre_capitalization ~w(d' l')
  @middle_capitalization ~w(( -)

  @cities ~w(
    amiens
    angers
    avignon
    besancon
    bordeaux
    brest
    caen
    cergy
    chambery
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
    marne
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
    bernard
    bourgogne
    bretagne
    caledonie
    cambresis
    cezanne
    champagne
    charles
    claude
    corse
    dauphine
    denis
    essonne
    est
    etienne
    france
    franche
    francois
    gaulle
    hainaut
    jaures
    jean
    jules
    monnet
    moulin
    nord
    normandie
    ouest
    paul
    picardie
    pontoise
    provence
    quentin
    rabelais
    reunion
    roussillon
    sabatier
    saint
    savoie
    segalen
    sophia
    sorbonne
    sud
    vernes
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

  def find_by_slug_or_closer_distance_match(klass, slug, tolerance \\ 0.95) do
    case Repo.get_by(klass, slug: slug) do
      nil ->
        all_elements = Repo.all(klass)
        best_match = Enum.max_by(all_elements, &custom_jaro_distance(slug, &1.slug))
        best_match_distance = custom_jaro_distance(slug, best_match.slug)

        if best_match_distance > tolerance do
          FileLogger.log_into_file("""
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
      case word do
        "UNIVERSITE" -> "Université"
        "MINISTERE" -> "Ministère"
        "DEFENSE" -> "Défense"
        "L'INTERIEUR" -> "l'intérieur"
        <<"(" :: utf8, _r :: binary>> = w -> w
        w ->
          if (i == 0 || Enum.member?(@cities ++ @other_capitalize_nouns, Vae.String.parameterize(w))) do
            smarter_capitalize(w)
          else
            String.downcase(w)
          end
      end
    end)
    |> Enum.map(&replace_roman_numbers(&1))
    |> Enum.join(" ")
  end

  def smarter_capitalize(w) do
    Enum.reduce(@middle_capitalization, w, fn mc, res ->
      String.split(res, mc)
      |> Enum.map(&ignore_apostrophes(&1))
      |> Enum.join(mc)
    end)
  end

  def ignore_apostrophes(w) do
    case Enum.find(@pre_capitalization, &String.starts_with?(w, &1)) do
      nil -> String.capitalize(w)
      hd -> "#{hd}#{String.capitalize(String.replace_prefix(w, hd, ""))}"
    end
  end

end