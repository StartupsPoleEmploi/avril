defmodule Vae.String do
  def titleize(string) do
    cond do
      String.upcase(string || "") == string ->
        String.split(string, " ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
      true                                  -> string
    end
  end

  def parameterize(string) do
    string
      |> String.normalize(:nfd)
      |> String.replace(~r/[^A-z\s]/u, "")
      |> String.downcase()
      |> String.trim()
      |> String.replace(~r/\s+/, "-")
  end
end