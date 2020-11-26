defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Certification, Delegate, Repo, Rome}
  import Ecto.Query
  import SweetXml
  alias Vae.Authorities.Rncp.FileLogger

  @ignored_certifier_slugs ~w(
    universite-de-nouvelle-caledonie
    universite-de-la-nouvelle-caledonie
    universite-de-la-polynesie-francaise
    sncf-universite-de-la-surete
    universite-du-vin
    universite-scienchumaines-lettres-arts
    universite-de-technologie-belfort-montbeliard
    universite-catholique-de-l-ouest
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

  @slugs %{
    mes: "ministere-de-l-enseignement-superieur",
    men: "ministere-de-l-education-nationale",
    mcs: "ministere-charge-de-la-solidarite"
  }

  def buildable_certifier?(name) do
    slug = Vae.String.parameterize(name)
    String.contains?(slug, "universite") &&
      not String.contains?(slug, "polytech") &&
      not Enum.member?(@ignored_certifier_slugs, slug)
  end

  def accepted_fiche?(fiche) do
    accessible_vae = xpath(fiche, ~x"./SI_JURY_VAE/text()"s) == "Oui"

    intitule = xpath(fiche, ~x"./INTITULE/text()"s) |> String.downcase()
    ignored_intitule = @ignored_certifications
      |> Enum.any?(&String.starts_with?(intitule, String.downcase(&1)))

    accessible_vae && !ignored_intitule
  end

  def reject_educ_nat_certifiers(certifiers, %{
    acronym: acronym,
    rncp_id: rncp_id,
    label: label,
    is_currently_active: is_currently_active
  }) do
    Enum.reject(certifiers, fn %Certifier{slug: slug} ->
      is_educ_nat = slug == @slugs[:men]
      is_ignored_acronym = Enum.member?(@ignored_acronyms_for_educ_nat, acronym)
      is_custom_rncp = rncp_id in ["4505"]
      if is_educ_nat && (is_ignored_acronym || is_custom_rncp)  do
        FileLogger.log_into_file("men_rejected.csv", [rncp_id, acronym, label, is_currently_active])
        true
      end
    end)
  end

  def add_educ_nat_certifiers(certifiers, %{
    acronym: acronym,
    rncp_id: rncp_id,
    is_currently_active: is_currently_active
  }) do
    is_enseignement_superieur = Enum.any?(certifiers, &(&1.slug == @slugs[:mes]))
    is_solidarite = Enum.any?(certifiers, &(&1.slug == @slugs[:mcs]))
    is_bts = acronym == "BTS"
    is_in_custom_list = rncp_id in ["4877", "4875", "34825", "34828"]

    if is_currently_active && (is_solidarite || (is_enseignement_superieur && (is_bts || is_in_custom_list))) do
      certifiers ++ [Repo.get_by(Certifier, slug: @slugs[:men])]
    else
      certifiers
    end
  end

  def custom_data_transformations(%{
    rncp_id: "23909"
  } = data) do
    Map.merge(data, %{acronym: "BATC"})
  end

  def custom_data_transformations(%{
    rncp_id: rncp_id,
    acronym: acronym
  } = data) when rncp_id in ["4504", "31191", "5440"] or acronym == "BEP" do
    Map.merge(data, %{is_active: false})
  end

  def custom_data_transformations(%{
    rncp_id: "4877",
    romes: romes
  } = data) do
    Map.merge(data, %{romes: romes ++ [Repo.get_by(Rome, code: "M1203")]})
  end

  def custom_data_transformations(%{
    rncp_id: "492",
    certifiers: certifiers
  } = data) do
    Map.merge(data, %{certifiers: Enum.reject(certifiers, &(&1.slug == "ministere-de-la-jeunesse-des-sports-et-de-la-cohesion-sociale"))})
  end

  def custom_data_transformations(data), do: data

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
end