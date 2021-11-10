defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Repo, Rome}
  import SweetXml
  alias Vae.Authorities.Rncp.FileLogger

  @current_year Date.utc_today().year

  @ignored_fiche_intitules [
    "Un des meilleurs ouvriers de France",
    "Ecole polytechnique",
  ]

  @ignored_fiche_acronyms [
    "BEPA"
  ]

  @ignored_acronyms_for_educ_nat [
    "CQP",
    "DEUST",
    "DUT",
    "MASTER",
    "Licence Professionnelle",
    "Titre ingénieur",
  ]

  @cci_certifications_rncp_ids ~w(
    11200 23827 23869 23872 23932
    23937 23939 23940 26901 27095
    27096 27365 27413 28669 28764
    29535 32362 34353 34928 34965
    34999 35001 35010
  )

  @wrong_educ_nat_certifiers ~w(
    230 367 2028 2514 4495 4496 4500 4503 4505
    18363 25467 28557 34824 34827 34829 34862
  )
  @missing_educ_nat_certifiers ~w(4875 34825 34826 34828 35044)

  @educ_nat "ministere-de-l-education-nationale"
  @ens_sup "ministere-de-l-enseignement-superieur"
  @solidarite "ministere-charge-de-la-solidarite"
  @sports "ministere-de-la-jeunesse-des-sports-et-de-la-cohesion-sociale"

  def cci_certifications_rncp_ids(), do: @cci_certifications_rncp_ids
  def wrong_educ_nat_certifiers(), do: @wrong_educ_nat_certifiers
  def missing_educ_nat_certifiers, do: @missing_educ_nat_certifiers

  def accepted_fiche?(fiche) do
    accessible_vae = xpath(fiche, ~x"./SI_JURY_VAE/text()"s) == "Oui"

    intitule = xpath(fiche, ~x"./INTITULE/text()"s) |> String.downcase()
    ignored_intitule = @ignored_fiche_intitules
      |> Enum.any?(&String.starts_with?(intitule, String.downcase(&1)))

    acronym = xpath(fiche, ~x"./ABREGE/CODE/text()"s)
    ignored_acronym = acronym in @ignored_fiche_acronyms

    accessible_vae && !ignored_intitule && !ignored_acronym
  end

  def reject_educ_nat_certifiers(certifiers, %{
    acronym: acronym,
    rncp_id: rncp_id,
    label: label,
    is_rncp_active: is_rncp_active
  }) do
    Enum.reject(certifiers, fn %Certifier{slug: slug} ->
      is_educ_nat = slug == @educ_nat
      is_ignored_acronym = Enum.member?(@ignored_acronyms_for_educ_nat, acronym)
      is_custom_rncp = rncp_id in @wrong_educ_nat_certifiers
      if is_educ_nat && (is_ignored_acronym || is_custom_rncp) do
        FileLogger.log_into_file("men_rejected.csv", [rncp_id, acronym, label, is_rncp_active])
        true
      else
        false
      end
    end)
  end

  def add_educ_nat_certifiers(certifiers, %{
    acronym: acronym,
    rncp_id: rncp_id,
    is_rncp_active: is_rncp_active
  }) do
    is_enseignement_superieur = Enum.any?(certifiers, &(&1.slug == @ens_sup))
    is_solidarite = Enum.any?(certifiers, &(&1.slug == @solidarite))
    is_bts = acronym == "BTS"
    is_in_custom_list = rncp_id in @missing_educ_nat_certifiers

    if is_rncp_active && (is_solidarite || (is_enseignement_superieur && (is_bts || is_in_custom_list))) do
      certifiers ++ [Repo.get_by(Certifier, slug: @educ_nat)]
    else
      certifiers
    end
  end

  def custom_data_transformations(%{
    certifiers: [%Certifier{slug: @educ_nat} | _],
    end_of_rncp_validity: %Date{year: year, month: month}
  } = data) when year == @current_year and month >= 7 do
    Map.merge(data, %{is_active: false})
  end

  def custom_data_transformations(%{
    rncp_id: "23909"
  } = data) do
    Map.merge(data, %{acronym: "BATC"})
  end

  def custom_data_transformations(%{
    rncp_id: rncp_id,
    acronym: acronym
  } = data) when rncp_id in ["4504", "31191", "5440", "462"] or acronym == "BEP" do
    Map.merge(data, %{is_active: false})
  end

  def custom_data_transformations(%{
    rncp_id: rncp_id,
  } = data) when rncp_id in ["25520", "25522", "25471"] do
    Map.merge(data, %{is_active: true})
  end

  def custom_data_transformations(%{
    rncp_id: "4877",
    romes: romes
  } = data) do
    Map.merge(data, %{romes: romes ++ [Repo.get_by(Rome, code: "M1203")]})
  end

  def custom_data_transformations(%{
    rncp_id: "25467",
    romes: romes
  } = data) do
    Map.merge(data, %{romes: romes ++ [Repo.get_by(Rome, code: "K1304")]})
  end

  def custom_data_transformations(%{
    rncp_id: "492",
    certifiers: certifiers
  } = data) do
    Map.merge(data, %{certifiers: Enum.reject(certifiers, &(&1.slug == @sports))})
  end

  def custom_data_transformations(%{
    rncp_id: rncp_id,
    certifiers: [%Certifier{slug: "cci-france"} | _]
  } = data) when rncp_id not in @cci_certifications_rncp_ids do
    Map.merge(data, %{is_active: false})
  end

  def custom_data_transformations(data), do: data
end