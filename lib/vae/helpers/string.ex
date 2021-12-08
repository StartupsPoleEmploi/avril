defmodule Vae.String do
  @moduledoc """
  `String` method helpers
  """

  def is_blank?(nil), do: true
  def is_blank?(str) when is_binary(str), do: String.trim(str) == ""
  def is_blank?(_), do: false

  def is_present?(str), do: not is_blank?(str)

  def blank_is_nil(v, map_fn \\ fn e -> e end), do: if(is_blank?(v), do: nil, else: map_fn.(v))

  def encode(string) do
    :crypto.hash(:md5, string |> Base.encode16())
  end

  def to_id(param) when is_binary(param) do
    param
    |> String.split("-")
    |> List.first()
    |> String.to_integer()
  end

  def to_id(_param), do: nil

  def wordify(word) do
    String.split(word, ~r/\s+/)
  end

  def titleize(string) do
    cond do
      String.upcase(string || "") == string ->
        String.split(string, " ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")

      true ->
        string
    end
  end

  def capitalize(nil), do: nil
  def capitalize(s), do: String.capitalize(s)

  def parameterize(string, separator \\ "-")
  def parameterize(nil, _), do: nil

  def parameterize(string, separator) do
    string
    |> :unicode.characters_to_nfd_binary()
    |> String.replace("œ", "oe")
    |> String.replace(~r/[\\"\'\’\-\(\)]/u, " ")
    |> String.replace(~r/[^A-z\s0-9]/u, "")
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/\s+/, separator)
  end

  defp plural_letter(word) do
    cond do
      String.ends_with?(word, "au") -> "x"
      Regex.match?(~r/\d+/, word) -> ""
      String.ends_with?(word, "s") -> ""
      true -> "s"
    end
  end

  defp pluralize_word(word) do
    cond do
      is_blank?(word) -> word
      word == "Son" -> "Ses"
      word == "la" -> "les"
      true -> "#{word}#{plural_letter(word)}"
    end
  end

  def pluralize(words, opts \\ []) do
    if opts[:lang] == :en do
      pluralize_word(words)
    else
      String.split(words, " ") |> Enum.map(&pluralize_word/1) |> Enum.join(" ")
    end
  end

  def inflect(w, c, opts \\ [])
  def inflect(words, count, opts) when is_binary(words) and is_integer(count) do
    if count > 1 do
      pluralize(words, opts)
    else
      words
    end
  end

  def inflect(count, words, opts) when is_binary(words) and is_integer(count) do
    "#{count} #{inflect(words, count, opts)}"
  end

  def prepend_if_not_repeat(prepend, string) do
    if String.starts_with?(String.downcase(string), String.downcase(prepend)), do: string, else: "#{prepend} #{string}"
  end
end
