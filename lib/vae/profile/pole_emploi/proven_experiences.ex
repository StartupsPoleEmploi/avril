defmodule Vae.Profile.ProvenExperiences do
  @path "https://api.emploi-store.fr/partenaire/peconnect-experiencesprofessionellesdeclareesparlemployeur/v1/contrats"

  def execute(token) do
    build_urls()
    |> call(token)
    |> format()
  end

  def build_urls(i \\ 1, acc \\ [])

  def build_urls(i, acc) do
    case i do
      1 ->
        build_urls(i + 1, [build() | acc])

      i when i <= 5 ->
        end_date = Timex.shift(Timex.today(), years: -2 * (i - 1))

        build_urls(
          i + 1,
          [
            build(end_date) | acc
          ]
        )

      _ ->
        acc
    end
  end

  def build(end_date \\ Timex.today())

  def build(end_date) do
    Timex.shift(end_date, years: -2 * 1, days: 1)
    |> build_from_date(end_date)
  end

  def build_from_date(start_date, end_date) do
    "#{@path}?dateDebutPeriode=#{format_date(start_date)}&dateFinPeriode=#{format_date(end_date)}&uniteDureeTravail=h"
  end

  def call(urls, token) do
    urls
    |> Enum.map(fn url ->
      Vae.OAuth.get(token, url)
    end)
    |> Enum.flat_map(fn %OAuth2.Response{body: %{"contrats" => contracts}} ->
      contracts
    end)
    |> Enum.uniq_by(fn contract -> contract["dateDebut"] end)
  end

  def format(experiences) do
    %{
      proven_experiences:
        Enum.map(
          experiences,
          &Vae.ProvenExperience.experiencesprofessionellesdeclareesparlemployeur_api_map/1
        )
    }
  end

  def is_data_missing(_user), do: true

  defp format_date(date) do
    Timex.format!(date, "{YYYY}{0M}{0D}")
  end
end
