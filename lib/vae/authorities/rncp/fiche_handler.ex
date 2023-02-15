defmodule Vae.Authorities.Rncp.FicheHandler do
  require Logger
  # import SweetXml
  import Ecto.Query
  alias Vae.{Certification, Certifier, Rome, Repo}
  alias Vae.Authorities.Rncp.{AuthorityMatcher, CustomRules}

  def rncp_to_certification() do
    [
      rncp_id: {"NUMERO_FICHE", &String.replace_prefix(&1, "RNCP", "")},
      label: {"INTITULE", &String.slice(&1, 0, 225)},
      acronym: {"ABREGE/CODE", fn a -> if a != "Autre", do: a end},
      activities: {"ACTIVITES_VISEES", &HtmlEntities.decode/1},
      abilities: {"CAPACITES_ATTESTEES", &HtmlEntities.decode/1},
      activity_area: {"SECTEURS_ACTIVITE", &(&1)},
      accessible_job_type: {"TYPE_EMPLOI_ACCESSIBLES", &(&1)},
      level: {"NOMENCLATURE_EUROPE/NIVEAU", fn l ->
        l
        |> String.replace_prefix("NIV", "")
        |> case do
          num when is_integer(num) -> num
          str when is_binary(str) ->
            case Integer.parse(str) do
              {int, _rest} -> int
              _ -> nil
            end
          _ -> nil
        end
      end},
      is_rncp_active: {"ACTIF", &(&1 == "Oui")},
      is_active: {nil, &(&1["ACTIF"] == "Oui" && CustomRules.accepted_fiche?(&1))},
      end_of_rncp_validity: {"DATE_FIN_ENREGISTREMENT", fn d ->
        case Timex.parse(d, "%d/%m/%Y", :strftime) do
          {:ok, datetime} -> datetime |> DateTime.to_date()
          _ -> nil
        end
      end},
      romes: {"CODES_ROME", fn rome_data ->
        codes = Enum.map((rome_data || []), &(&1["CODE"]))
        Repo.all(from r in Rome, [where: r.code in ^codes])
      end},
      certifiers: {"CERTIFICATEURS", fn (certificateurs_data, data) ->
        Enum.map(certificateurs_data || [], fn %{
          "NOM_CERTIFICATEUR" => certificateur_name
        } = cd ->
          certificateur_params = %{
            name: AuthorityMatcher.prettify_name(certificateur_name),
            siret: (if cd["SIRET_CERTIFICATEUR"], do: String.replace(cd["SIRET_CERTIFICATEUR"], ~r/\s+/, ""))
          }
          match_or_build_certifier(certificateur_params)
        end)
        |> Enum.filter(&not(is_nil(&1)))
        |> CustomRules.transform_certifiers(data)
        |> Enum.uniq_by(&(&1.slug))
        |> Enum.sort_by(&(&1.id))
      end},
      newer_certification: {"NOUVELLE_CERTIFICATION", fn new_certification_data ->
        if new_certification_data do
          new_certification_data
          |> String.replace_prefix("RNCP", "")
          |> (&Repo.get_by(Certification, %{rncp_id: &1})).()
        end
      end},
      older_certification: {"ANCIENNE_CERTIFICATION", fn old_certification_data ->
        if old_certification_data do
          old_certification_data
          |> String.replace_prefix("RNCP", "")
          |> (&Repo.get_by(Certification, %{rncp_id: &1})).()
        end
      end}
    ]
  end

  def api_fiche_to_certification_params(nil), do: %{}

  def api_fiche_to_certification_params(api_data) do
    Enum.reduce(rncp_to_certification(), %{}, fn({key, {path, func}}, result) ->
      sub_data = if path, do: get_in(api_data, String.split(path, "/")), else: api_data
      value = if is_function(func, 2), do: func.(sub_data, result), else: func.(sub_data)
      Map.put(result, key, value)
    end)
    |> CustomRules.custom_data_transformations()
  end

  def match_or_build_certifier(%{name: name} = params, opts \\ []) do
    siret_param = params[:siret]
    case AuthorityMatcher.find_by_siret(params) || AuthorityMatcher.find_by_slug_or_closer_distance_match(Certifier, name, opts[:tolerance]) do
      %Certifier{siret: siret} = c when is_nil(siret) and not is_nil(siret_param) ->
        Certifier.changeset(c, %{siret: siret_param}) |> Repo.update!()
      %Certifier{} = c ->
        c
      nil ->
        # if opts[:build] == :force || (AuthorityMatcher.buildable_certifier?(name) && opts[:build] == :allow) do
          create_certifier_and_maybe_delegate(params, opts)
        # end
    end
  end

  def create_certifier_and_maybe_delegate(%{name: _name} = params, _opts \\ []) do
    %Certifier{}
    |> Certifier.changeset(params)
    # |> FileLogger.log_changeset()
    # |> Repo.insert!()
  end

  def ensure_certifiers(%Ecto.Changeset{} = changeset), do: Ecto.Changeset.apply_changes(changeset)
  def ensure_certifiers(%Certifier{} = certifier), do: certifier

end