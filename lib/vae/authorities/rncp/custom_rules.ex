defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Certification, Delegate, Repo}
  import Ecto.Query
  alias Vae.Authorities.Rncp.AuthorityMatcher

  @ignored_certifier_slugs ~w(
    universite-de-nouvelle-caledonie
    universite-de-la-nouvelle-caledonie
    universite-de-la-polynesie-francaise
    sncf-universite-de-la-surete
    universite-du-vin
    universite-scienchumaines-lettres-arts
    universite-de-technologie-belfort-montbeliard
    universite-paris-lumiere
    ecole-polytechnique-de-l-universite-de-tours-polytech-tours
    centre-universitaire-des-sciences-et-techniques-de-l-universite-clermont-ferrand
  )

  @ignored_certifications [
    "Un des meilleurs ouvriers de France",
    "Ecole polytechnique"
  ]

  @ignored_acronyms_for_educ_nat [
    "CQP",
    "DEUST",
    "DUT",
    "MASTER",
    "Licence Professionnelle",
    "Titre ingénieur",
  ]

  # @overrides %{
  #   "Communaute d universites et etablissements Université Paris saclay" => "Université Paris-Saclay",
  #   "Université paris-sud - Paris 11" => "Université Paris-Saclay",
  #   "Université de Corse p paoli" => "Université de Corse - Pasquale Paoli",
  #   "Conservatoire national des arts et métiers (CNAM)" => "CNAM",
  #   "MINISTERE DE L'EDUCATION NATIONALE ET DE LA JEUNESSE" => "Ministère de l'Education Nationale",
  #   "MINISTERE CHARGE DES AFFAIRES SOCIALES" => "Ministère des affaires sociales et de la santé",
  #   "Ministère chargé de la santé " => "Ministère des affaires sociales et de la santé",
  #   "Ministère chargé de l'Emploi" => "Ministère du travail",
  #   "Ministère du Travail - Délégation Générale à l'Emploi et à la Formation Professionnelle (DGEFP)" => "Ministère du travail",
  #   "Ministère chargé des sports et de la jeunesse" => "Ministère de la jeunesse, des sports et de la cohésion sociale",
  #   "Ministère de l'Education nationale et de la jeunesse" => "Ministère de l'Education Nationale",
  #   "Ministère de l’enseignement supérieur, de la recherche et de l’innovation" => "Ministère de l'Enseignement Supérieur",
  #   "Ministère de la Défense" => "Ministère des Armées",
  #   "Ministère de l'agriculture et de la pêche" => "Ministère chargé de l'agriculture",
  # }

  def buildable_certifier?(name) do
    slug = Vae.String.parameterize(name)
    String.contains?(slug, "universite") && not Enum.member?(@ignored_certifier_slugs, slug)
  end

  def rejected_fiche?(text) do
    @ignored_certifications
      |> Enum.any?(&String.starts_with?(String.downcase(text), String.downcase(&1)))
  end

  def filtered_certifiers(certifiers, acronym) do
    Enum.reject(certifiers, fn c ->
      Certifier.is_educ_nat?(c) && Enum.member?(@ignored_acronyms_for_educ_nat, acronym)
    end)
  end

  # def certifier_rncp_override(name) do
  #   case Enum.find(@overrides, fn {k, _v} ->
  #     String.starts_with?(Vae.String.parameterize(name), Vae.String.parameterize(k))
  #   end) do
  #     {_k, val} -> val
  #     nil -> name
  #   end
  # end

  def custom_acronym() do
    Logger.info("Statically setting BATC acronym")
    Repo.get_by(Certification, rncp_id: "23909")
    |> Certification.changeset(%{acronym: "BATC"})
    |> Repo.update()
  end

  def deactivate_deamp() do
    Logger.info("Statically deactivating DEAMP")
    Repo.get_by(Certification, rncp_id: "4504")
    |> Certification.changeset(%{is_active: false})
    |> Repo.update()
  end

  def deactivate_all_bep() do
    Logger.info("Statically deactivating all BEP")
    from(c in Certification, where: [acronym: "BEP"])
    |> Repo.update_all(set: [is_active: false])
  end

  def deactivate_culture_ministry_certifications() do
    Logger.info("Statically deactivating certifications Ministère de la culture")
    Repo.get_by(Certifier, slug: "ministere-charge-de-la-culture")
    |> Repo.preload(:certifications)
    |> Map.get(:certifications)
    |> Enum.each(fn c ->
      c
      |> Certification.changeset(%{is_active: false})
      |> Repo.update()
    end)
  end

  def match_cci_former_certifiers() do
    %Certifier{} = cci_france = Repo.get_by(Certifier, slug: "cci-france")
    |> Repo.preload([:certifications, [delegates: :certifiers]])

    other_delegates = from(d in Delegate,
      where: like(d.name, "CCI%"),
      preload: [:certifiers]
    )
    |> Repo.all()

    Enum.uniq(cci_france.delegates ++ other_delegates)
    |> Enum.each(fn d ->

      previous_certifications = d.certifiers
      |> Enum.flat_map(&get_certifier_previous_certifications(&1))

      extra_certifications =
        Enum.reject(previous_certifications, &Enum.member?(cci_france.certifications, &1))

      rejected_certifications =
        Enum.reject(cci_france.certifications, &Enum.member?(previous_certifications, &1))

      d
      |> Delegate.changeset(%{
        certifiers: d.certifiers ++ [cci_france],
        included_certifications: extra_certifications,
        excluded_certifications: rejected_certifications
      })
      |> Repo.update()
    end)

    # IO.gets("Regarde les logs puis entrée pour terminer.")
  end

  defp get_certifier_previous_certifications(certifier) do
    (certifier.internal_notes || "")
    |> String.split(",")
    |> Enum.map(fn id ->
      case Integer.parse(id) do
        :error -> nil
        {int, _rest} -> int
      end
    end)
    |> Enum.reject(&is_nil(&1))
    |> case do
      [] -> []
      ids ->
        (from cf in Certification,
          where: cf.id in ^ids and cf.is_active == true
        ) |> Repo.all()
    end
  end

  def associate_some_enseignement_superieur_to_education_nationale() do
    mes = Repo.get_by(Certifier, slug: "ministere-de-l-enseignement-superieur")

    men = Repo.get_by(Certifier, slug: "ministere-de-l-education-nationale")

    from(c in Certification,
      join: certifier in assoc(c, :certifiers),
      where: c.is_active and certifier.id == ^mes.id and (c.acronym == "BTS" or c.rncp_id in ["4877", "4875"])
    )
    |> Repo.all()
    |> Enum.each(fn c ->
      c = Repo.preload(c, :certifiers)
      Certification.changeset(c, %{
        certifiers: c.certifiers ++ [men]
      })
      |> Repo.update()
    end)
  end

  def special_rules_for_educ_nat() do
    certification = Repo.get_by(Certification, rncp_id: "4505")
    |> Repo.preload(:certifiers)

    certification
    |> Certification.changeset(%{
      certifiers: Enum.reject(certification.certifiers, &Certifier.is_educ_nat?(&1))
    })
    |> Repo.update()

    certification = Repo.get_by(Certification, rncp_id: "31191")
    |> Certification.changeset(%{
      is_active: false
    })
    |> Repo.update()
  end
end