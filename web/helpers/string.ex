defmodule Vae.String do
  def titleize(string) do
    cond do
      String.upcase(string || "") == string ->
        String.split(string, " ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
      true                                  -> string
    end
  end
end