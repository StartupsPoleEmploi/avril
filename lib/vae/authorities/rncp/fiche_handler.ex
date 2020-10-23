defmodule Vae.Authorities.Rncp.FicheHandler do
  require Logger
  import Ecto.Query
  import SweetXml
  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}
  alias Vae.Authorities.Rncp.{AuthorityMatcher, CustomRules}

  def fiche_to_certification(fiche) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    Logger.info("Updating RNCP_ID: #{rncp_id}")

    data = SweetXml.xmap(fiche,
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
      is_currently_active: ~x"./ACTIF/text()"s |> transform_by(&(&1 == "Oui")),
      will_soon_be_inactive: ~x"./DATE_FIN_ENREGISTREMENT/text()"s |> transform_by(fn d ->
        with(
          {:ok, datetime} <- Timex.parse(d, "%d/%m/%Y", :strftime),
          date <- datetime |> DateTime.to_date()
        ) do
          today = Date.utc_today()
          Timex.after?(today, Timex.set(today, [month: 6, day: 30])) &&
          Timex.before?(date, Timex.end_of_year(today))
        end
      end)
    )

    romes = SweetXml.xpath(fiche, ~x"./CODES_ROME/ROME"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./CODE/text()"s) end)
      |> Enum.map(fn code -> Repo.get_by(Rome, code: code) end)

    certifiers = SweetXml.xpath(fiche, ~x"./CERTIFICATEURS/CERTIFICATEUR"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./NOM_CERTIFICATEUR/text()"s) end)
      |> Enum.map(&AuthorityMatcher.prettify_name/1)
      |> Enum.map(&match_or_build_certifier(&1, [with_delegate: true, build: (if data.is_currently_active, do: :allow)]))
      |> Enum.filter(&not(is_nil(&1)))
      |> CustomRules.filtered_certifiers(data.acronym)
      |> Enum.uniq_by(&(&1.slug))

    is_educ_nat = Enum.any?(certifiers, &Certifier.is_educ_nat?(&1))

    data
    |> Map.merge(%{
      is_active: data.is_currently_active && (if is_educ_nat, do: !data.will_soon_be_inactive, else: true),
      rncp_id: rncp_id,
      romes: romes,
      certifiers: certifiers
    })
    |> insert_or_update_by_rncp_id()
  end

  def move_applications_if_inactive_and_set_newer_certification(fiche, options) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    with(
      %Certification{id: certification_id, is_active: false} = certification <-
        Repo.get_by(Certification, rncp_id: rncp_id) |> Repo.preload([:newer_certification]),
      newer_rncp_id when not is_nil(newer_rncp_id) <-
        SweetXml.xpath(fiche, ~x"./NOUVELLE_CERTIFICATION/text()"s
          |> transform_by(fn nb ->
            String.replace_prefix(nb, "RNCP", "")
          end)),
      %Certification{id: newer_certification_id, is_active: true} = newer_certification <-
        Repo.get_by(Certification, rncp_id: newer_rncp_id),
      {:ok, _} <- Certification.changeset(certification, %{newer_certification: newer_certification}) |> Repo.update()
    ) do
      try do
        from(a in UserApplication,
          where: [certification_id: ^certification_id]
        ) |> Repo.update_all(set: [certification_id: newer_certification_id])
      rescue
        e in Postgrex.Error ->
          Logger.warn(inspect(e))
          if options[:interactive] do
            id = IO.gets("Quel ID supprime-t-on ? ")
            |> String.trim()
            |> String.to_integer()

            Repo.get(UserApplication, id) |> Repo.delete()
          else
            Logger.warn("Ignored. Run with -i option to make it interactive")
          end
      end
    end
  end

  def match_or_build_certifier(name, opts \\ []) do
    case AuthorityMatcher.find_by_slug_or_closer_distance_match(Certifier, name, opts[:tolerance]) do
      %Certifier{} = c -> c
      nil ->
        if opts[:build] == :force || (CustomRules.buildable_certifier?(name) && opts[:build] == :allow) do
          create_certifier_and_maybe_delegate(name, opts)
        end
    end
  end

  def create_certifier_and_maybe_delegate(name, opts \\ []) do
    certifier = %Certifier{}
    |> Certifier.changeset(%{
      name: name
    }) |> Repo.insert!()

    if opts[:with_delegate] && (not is_nil(certifier)) do
      (AuthorityMatcher.find_by_slug_or_closer_distance_match(Delegate, name, opts[:tolerance]) ||
        %Delegate{name: name})
      |> Delegate.changeset(%{
        certifiers: [certifier]
      })
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
    |> Repo.insert_or_update()
  end
end