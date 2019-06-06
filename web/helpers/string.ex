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

  def parameterize(string, option\\"-") do
    string
      |> :unicode.characters_to_nfd_binary()
      |> String.replace(~r/[\'’\"\-]/u, " ")
      |> String.replace(~r/[^A-z\s0-9]/u, "")
      |> String.downcase()
      |> String.trim()
      |> String.replace(~r/\s+/, option)
  end

  def to_id(param) when is_binary(param) do
    if Regex.match?(~r/^\d+\-.*/, param), do: String.to_integer(List.first(String.split(param, "-"))), else: String.to_integer(param)
  end
  def to_id(v), do: v

end