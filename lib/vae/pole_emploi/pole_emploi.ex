defmodule Vae.PoleEmploi do
  require Logger

  alias Vae.PoleEmploi.Mappers
  alias Vae.PoleEmploi.OAuth
  alias Vae.PoleEmploi.OAuth.Clients

  @user_info_path "https://api.emploi-store.fr/partenaire/peconnect-individu/v1/userinfo"
  @civil_status_path "https://api.emploi-store.fr/partenaire/peconnect-datenaissance/v1/etat-civil"
  @experiences_path "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences"
  @contact_path "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees"
  @proven_experiences_path "https://api.emploi-store.fr/partenaire/peconnect-experiencesprofessionellesdeclareesparlemployeur/v1/contrats"
  @skills_path "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences"

  def get_user_info(state, code) do
    {:ok, token} = get_token(state, code)

    token
    |> get(@user_info_path)
    |> case do
      {:ok, user_info} ->
        {:ok, {token, user_info}}

      error ->
        error
    end
  end

  def fetch_all(map, token) do
    [
      {Mappers.CivilStatusMapper, &get_civil_status/1},
      {Mappers.ExperiencesMapper, &get_experiences/1},
      {Mappers.ContactMapper, &get_contact/1},
      {Mappers.ProvenExperiencesMapper, &get_proven_experiences/1},
      {Mappers.SkillsMapper, &get_skills/1}
    ]
    |> Enum.map(fn {mapper, f} ->
      Task.async(fn ->
        if(is_missing?(mapper, map)) do
          f.(token)
        else
          %{}
        end
      end)
    end)
    |> Enum.map(&Task.await(&1, 15_000))
  end

  def is_missing?(mapper, map), do: apply(mapper, :is_missing?, [map])

  def get_civil_status(token), do: get(token, @civil_status_path, Mappers.CivilStatusMapper)

  def get_experiences(token), do: get(token, @experiences_path, Mappers.ExperiencesMapper)

  def get_contact(token), do: get(token, @contact_path, Mappers.ContactMapper)

  def get_proven_experiences(token) do
    paths = build_proven_experiences_queries()
    get(token, paths, Mappers.ProvenExperiencesMapper)
  end

  def get_skills(token), do: get(token, @skills_path, Mappers.SkillsMapper)

  defp get_token(state, code) do
    Clients.get_client(state)
    |> OAuth.generate_access_token(code)
  end

  defp get(token, path, mapper \\ nil)

  defp get(token, path, nil = _mapper) do
    with %OAuth2.Response{body: body} <- OAuth.get(token, path) do
      {:ok, body}
    else
      error ->
        Logger.error(fn -> inspect(error) end)
        {:error, error}
    end
  end

  defp get(token, path, mapper) when is_list(path) do
    responses = Enum.map(path, &OAuth.get(token, &1))
    apply(mapper, :map, [responses])
  end

  defp get(token, path, mapper) do
    response = OAuth.get(token, path)
    apply(mapper, :map, [response])
  end

  defp build_proven_experiences_queries(i \\ 1, acc \\ [])

  defp build_proven_experiences_queries(i, acc) do
    case i do
      1 ->
        build_proven_experiences_queries(i + 1, [from() | acc])

      i when i <= 5 ->
        end_date = Timex.shift(Timex.today(), years: -2 * (i - 1))

        build_proven_experiences_queries(
          i + 1,
          [
            from(end_date) | acc
          ]
        )

      _ ->
        acc
    end
  end

  defp from(end_date \\ Timex.today())

  defp from(end_date) do
    Timex.shift(end_date, years: -2 * 1, days: 1)
    |> build_from_date(end_date)
  end

  defp build_from_date(start_date, end_date) do
    "#{@proven_experiences_path}?dateDebutPeriode=#{format_date(start_date)}&dateFinPeriode=#{
      format_date(end_date)
    }&uniteDureeTravail=h"
  end

  defp format_date(date) do
    Timex.format!(date, "{YYYY}{0M}{0D}")
  end
end