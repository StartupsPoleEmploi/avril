defmodule Vae.Authorities.Rncp.AuthorityMatcher do
  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}
  @log_file "priv/matches.log"

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

  def clear_log_file() do
    Logger.info("Remove previous log file")
    File.rm(@log_file)
  end

  def log_into_file(content) do
    {:ok, file} = File.open(@log_file, [:append])
    IO.write(file, content)
    :ok = File.close(file)
  end

  def find_by_slug_or_closer_distance_match(klass, slug, tolerance \\ 0.95) do
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

  defp wordify_jaro_distance(string1, string2) do
    [short | [long | _rest]] = [wordify(string1), wordify(string2)]
    |> Enum.sort_by(&(length(&1)))

    short
    |> Enum.map(fn word1 ->
      long
      |> Enum.map(&custom_distance(word1, &1))
      |> Enum.max()
    end)
    |> (fn d ->
      case d do
        [] -> 0
        d -> Enum.sum(d)/length(d)
      end
    end).()
  end

  defp custom_distance(word1, word2) do
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
    |> Enum.filter(fn w -> Enum.member?(~w(de la le), w) end)
  end

  defp replace_roman_numbers(word) do
    @roman_numbers[String.downcase(word)] || word
  end

  def certifier_rncp_override(name) do
    case Enum.find(@overrides, fn {k, _v} ->
      String.starts_with?(Vae.String.parameterize(name), Vae.String.parameterize(k))
    end) do
      {_k, val} -> val
      nil -> name
    end
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

end