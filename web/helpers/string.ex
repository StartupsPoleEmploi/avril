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
      |> String.normalize(:nfd)
      |> String.replace(~r/[\'’\"\-]/u, " ")
      |> String.replace(~r/[^A-z\s0-9]/u, "")
      |> String.downcase()
      |> String.trim()
      |> String.replace(~r/\s+/, option)
  end
end