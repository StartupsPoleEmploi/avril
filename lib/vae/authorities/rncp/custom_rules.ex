defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Certification, Delegate, Repo}
  import Ecto.Query
  # alias Vae.Authorities.Rncp.AuthorityMatcher

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
    universite-europeenne-des-senteurs-et-des-saveurs
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

  def buildable_certifier?(name) do
    slug = Vae.String.parameterize(name)
    String.contains?(slug, "universite") &&
      not String.contains?(slug, "polytech") &&
      not Enum.member?(@ignored_certifier_slugs, slug)
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
      where: c.is_active and certifier.id == ^mes.id and c.acronym == "BTS"
    )
    |> Repo.all()
    |> Enum.each(fn c ->
      c = Repo.preload(c, :certifiers)
      Certification.changeset(c, %{
        certifiers: c.certifiers ++ [men]
      })
      |> Repo.update()
    end)

    from(c in Certification,
      join: certifier in assoc(c, :certifiers),
      where: certifier.id == ^mes.id and c.rncp_id in ["4877", "4875", "34825", "34828"]
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

  def deassociate_some_ministere_de_la_jeunesse() do
    mej = Repo.get_by(Certifier, slug: "ministere-de-la-jeunesse-des-sports-et-de-la-cohesion-sociale")

    cert = Repo.get_by(Certification, rncp_id: "492")
    |> Repo.preload(:certifiers)

    Certification.changeset(cert, %{
      certifiers: Enum.reject(cert.certifiers, &(&1.id == mej.id))
    }) |> Repo.update()
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