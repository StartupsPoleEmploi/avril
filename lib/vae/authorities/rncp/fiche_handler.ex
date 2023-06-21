defmodule Vae.Authorities.Rncp.FicheHandler do
  require Logger
  # import SweetXml
  import Ecto.Query
  alias Vae.{Certification, Certifier, Rome, Repo}
  alias Vae.Authorities.Rncp.{AuthorityMatcher, CustomRules}

  def transform_rncp_fields() do
    [
      rncp_id: {"NUMERO_FICHE", &String.replace_prefix(&1, "RNCP", "")},
      label: {"INTITULE", &String.slice(&1, 0, 225)},
      acronym: {"ABREGE/CODE", fn a -> if a != "Autre", do: a end},
      activities: {"ACTIVITES_VISEES", &HtmlEntities.decode/1},
      abilities: {"CAPACITES_ATTESTEES", &HtmlEntities.decode/1},
      activity_area: {"SECTEURS_ACTIVITE", &(&1)},
      accessible_job_type: {"TYPE_EMPLOI_ACCESSIBLES", &(&1)},
      jury_composition: {"SI_JURY_VAE/COMPOSITION", &(&1)},
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
      romes: {"CODES_ROME", fn rome_data -> Enum.map((rome_data || []), &(&1["CODE"])) end},
      newer_certification: {"NOUVELLE_CERTIFICATION",
        fn new_certification_data ->
          if new_certification_data, do: String.replace_prefix(new_certification_data, "RNCP", "")
        end
      },
      older_certification: {"ANCIENNE_CERTIFICATION",
        fn old_certification_data ->
          if old_certification_data, do: String.replace_prefix(old_certification_data, "RNCP", "")
        end
      },
      certifiers: {"CERTIFICATEURS", fn certificateurs_data ->
        Enum.map(certificateurs_data || [], fn %{
          "NOM_CERTIFICATEUR" => certificateur_name
        } = cd ->
          %{
            name: AuthorityMatcher.prettify_name(certificateur_name),
            siret: (if cd["SIRET_CERTIFICATEUR"], do: String.replace(cd["SIRET_CERTIFICATEUR"], ~r/\s+/, ""))
          }
        end)
      end},
    ]
  end

  def embed_with_associations() do
    [
      romes: &Repo.all(from r in Rome, [where: r.code in ^&1]),
      newer_certification: &Repo.get_by(Certification, %{rncp_id: &1}),
      older_certification: &Repo.get_by(Certification, %{rncp_id: &1}),
      certifiers: fn (certifiers_data, %{rncp_id: rncp_id} = fiche_data) ->

        certifiers_no_rncp =
          Repo.get_by(Certification, %{rncp_id: rncp_id})
          |> Repo.preload(:certifiers_no_rncp)
          |> case do
            nil -> []
            %Certification{certifiers_no_rncp: certifiers_no_rncp} -> certifiers_no_rncp
          end

        certifiers_rncp = Enum.map(certifiers_data, &match_or_build_certifier(&1))
        |> Enum.filter(&not(is_nil(&1)))
        |> CustomRules.transform_certifiers(fiche_data)
        |> Enum.uniq_by(&(&1.slug))
        |> Enum.sort_by(&(&1.id))
        |> Enum.reject(&(!&1.rncp_sync))

        certifiers_no_rncp ++ certifiers_rncp
      end
    ]
  end

  def api_fiche_to_certification_params(nil), do: %{}

  def api_fiche_to_certification_params(api_data) do
    transformed_fiche_data = Enum.reduce(transform_rncp_fields(), %{}, fn({key, {path, func}}, result) ->
      sub_data = if path, do: get_in(api_data, String.split(path, "/")), else: api_data
      value = if is_function(func, 2), do: func.(sub_data, result), else: func.(sub_data)
      Map.put(result, key, value)
    end)

    Enum.reduce(embed_with_associations(), transformed_fiche_data, fn({key, func}, result) ->
      sub_data = result[key]
      if sub_data do
        value = if is_function(func, 2), do: func.(sub_data, result), else: func.(sub_data)
        Map.put(result, key, value)
      else
        result
      end
    end)
    |> CustomRules.custom_data_transformations()
  end

  def match_or_build_certifier(%{name: name, siret: siret} = params, opts \\ []) do
    found_certifier = !is_nil(siret) && Repo.get_by(Certifier, siret: siret) ||
            AuthorityMatcher.find_by_slug_or_closer_distance_match(Certifier, name, opts[:tolerance])
    case found_certifier do
      %Certifier{siret: nil} = c when not is_nil(siret) ->
        Certifier.changeset(c, %{siret: siret}) |> Repo.update!()
      %Certifier{} = c ->
        c
      nil ->
        # if opts[:build] == :force || (AuthorityMatcher.buildable_certifier?(name) && opts[:build] == :allow) do
          create_certifier_and_maybe_delegate(params, opts)
        # end
    end
  end

  def create_certifier_and_maybe_delegate(params, _opts \\ []) do
    %Certifier{}
    |> Certifier.changeset(params)
    # |> FileLogger.log_changeset()
    # |> Repo.insert!()
  end

  def ensure_certifiers(%Ecto.Changeset{} = changeset), do: Ecto.Changeset.apply_changes(changeset)
  def ensure_certifiers(%Certifier{} = certifier), do: certifier

end