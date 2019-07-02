defmodule Vae.String do
  @moduledoc """
  `String` method helpers
  """

  def titleize(string) do
    cond do
      String.upcase(string || "") == string ->
        String.split(string, " ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
      true                                  -> string
    end
  end

  def parameterize(string, separator\\"-")
  def parameterize(nil, _), do: nil
  def parameterize(string, separator) do
    string
      |> :unicode.characters_to_nfd_binary()
      |> String.replace(~r/[\'’\"\-]/u, " ")
      |> String.replace(~r/[^A-z\s0-9]/u, "")
      |> String.downcase()
      |> String.trim()
      |> String.replace(~r/\s+/, separator)
  end

  def to_id(param) do
    if is_binary(param) && Regex.match?(~r/^\d+\-.*/, param) do
      case Integer.parse(param) do
        {int, _rest} -> int
        :error -> nil
      end
    else
      nil
    end
  end

end