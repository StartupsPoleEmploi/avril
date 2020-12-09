defmodule Vae.Authorities.Rncp.FicheHandler do
  require Logger
  import SweetXml
  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}
  alias Vae.Authorities.Rncp.{AuthorityMatcher, CustomRules, FileLogger}

  def fiche_to_certification(fiche, %{import_date: import_date}) do
    data = SweetXml.xmap(fiche,
      rncp_id: ~x"./NUMERO_FICHE/text()"s |> transform_by(&String.replace_prefix(&1, "RNCP", "")),
      label: ~x"./INTITULE/text()"s |> transform_by(&String.slice(&1, 0, 225)),
      acronym: ~x"./ABREGE/CODE/text()"s |> transform_by(fn a -> if a != "Autre", do: a end),
      activities: ~x"./ACTIVITES_VISEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      abilities: ~x"./CAPACITES_ATTESTEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      activity_area: ~x"./SECTEURS_ACTIVITE/text()"s,
      accessible_job_type: ~x"./TYPE_EMPLOI_ACCESSIBLES/text()"s,
      level: ~x"./NOMENCLATURE_EUROPE/NIVEAU/text()"s |> transform_by(fn l ->
        l
        |> String.replace_prefix("NIV", "")
        |> Vae.Maybe.if(&Vae.String.is_present?/1, &String.to_integer/1)
      end),
      is_rncp_active: ~x"./ACTIF/text()"s |> transform_by(&(&1 == "Oui")),
      end_of_rncp_validity: ~x"./DATE_FIN_ENREGISTREMENT/text()"s |> transform_by(fn d ->
        case Timex.parse(d, "%d/%m/%Y", :strftime) do
          {:ok, datetime} -> datetime |> DateTime.to_date()
          _ -> nil
        end
      end)
    )

    if data.is_rncp_active && data.end_of_rncp_validity == ~D[2024-01-01] do
      FileLogger.log_into_file("inactive_date.csv", [data.rncp_id, data.acronym, data.label])
    end

    Logger.info("Updating RNCP_ID: #{data.rncp_id}")

    data
    |> Map.merge(%{
      romes: parse_romes(fiche),
      certifiers: parse_certifiers(fiche, data),
      last_rncp_import_date: import_date
    })
    |> CustomRules.custom_data_transformations()
    |> insert_or_update_by_rncp_id()
  end

  def parse_romes(fiche) do
    SweetXml.xpath(fiche, ~x"./CODES_ROME/ROME"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./CODE/text()"s) end)
      |> Enum.map(fn code -> Repo.get_by(Rome, code: code) end)
  end

  def parse_certifiers(fiche, data) do
    SweetXml.xpath(fiche, ~x"./CERTIFICATEURS/CERTIFICATEUR"l)
      |> Enum.map(fn node ->
        SweetXml.xmap(node,
          name: ~x"./NOM_CERTIFICATEUR/text()"s |> transform_by(&AuthorityMatcher.prettify_name/1),
          siret: ~x"./SIRET_CERTIFICATEUR/text()"s |> transform_by(&String.replace(&1, ~r/\s+/, ""))
        )
      end)
      |> Enum.map(&match_or_build_certifier(&1, [with_delegate: true, build: (if data.is_rncp_active, do: :allow)]))
      |> Enum.filter(&not(is_nil(&1)))
      |> CustomRules.reject_educ_nat_certifiers(data)
      |> CustomRules.add_educ_nat_certifiers(data)
      |> Enum.uniq_by(&(&1.slug))
      |> Enum.sort_by(&(&1.id))
  end

  def move_applications_if_inactive_and_set_newer_certification(fiche) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    with(
      %Certification{is_rncp_active: false, applications: old_applications} = certification <-
        Repo.get_by(Certification, rncp_id: rncp_id) |> Repo.preload([:applications, :older_certification]),
      newer_rncp_id when not is_nil(newer_rncp_id) <-
        SweetXml.xpath(fiche, ~x"./NOUVELLE_CERTIFICATION/text()"l
          |> transform_by(fn l ->
            l
            |> Enum.map(&String.replace_prefix(to_string(&1), "RNCP", ""))
            |> Enum.sort_by(&String.to_integer(&1))
            |> List.last()
          end)
        ),
      %Certification{is_rncp_active: true, applications: new_applications} = newer_certification <-
        Repo.get_by(Certification, rncp_id: newer_rncp_id) |> Repo.preload(:applications)
    ) do

      Enum.each(old_applications, fn
        %UserApplication{user_id: user_id} = a1 ->
          if a2 = Enum.find(new_applications, &(&1.user_id == user_id)) do
            (if UserApplication.get_comparison_score(a1, a2) > 0, do: a2, else: a1)
            |> Repo.delete()
          end
      end)

      newer_certification
      |> Certification.changeset(%{older_certification: certification})
      |> Repo.update()
    end
  end

  def match_or_build_certifier(%{name: name} = params, opts \\ []) do
    siret_param = params[:siret]
    case AuthorityMatcher.find_by_siret(params) || AuthorityMatcher.find_by_slug_or_closer_distance_match(Certifier, name, opts[:tolerance]) do
      %Certifier{siret: siret} = c when is_nil(siret) and not is_nil(siret_param) ->
        Certifier.changeset(c, %{siret: siret}) |> Repo.update!()
      %Certifier{} = c -> c
      nil ->
        if opts[:build] == :force || (AuthorityMatcher.buildable_certifier?(name) && opts[:build] == :allow) do
          create_certifier_and_maybe_delegate(params, opts)
        end
    end
  end

  def create_certifier_and_maybe_delegate(%{name: name} = params, opts \\ []) do
    certifier = %Certifier{}
    |> Certifier.changeset(params)
    |> FileLogger.log_changeset()
    |> Repo.insert!()

    if opts[:with_delegate] && (not is_nil(certifier)) do
      (AuthorityMatcher.find_by_slug_or_closer_distance_match(Delegate, name, opts[:tolerance]) ||
        %Delegate{name: name})
      |> Delegate.changeset(%{
        certifiers: [certifier]
      })
      |> FileLogger.log_changeset()
      |> Repo.insert_or_update!()
    end

    certifier
  end

  defp insert_or_update_by_rncp_id(%{rncp_id: rncp_id} = fields) do
    Repo.get_by(Certification, rncp_id: rncp_id)
    |> case do
      nil -> %Certification{rncp_id: rncp_id}
      %Certification{} = c -> c
    end
    |> Repo.preload([:certifiers, :romes])
    |> Certification.changeset(fields)
    |> FileLogger.log_changeset()
    |> Repo.insert_or_update()
  end
end