defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Repo, Rome}
  import SweetXml
  alias Vae.Authorities.Rncp.FileLogger

  @current_year Date.utc_today().year

  @ignored_fiche_intitules [
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

  @cci_certifications_rncp_ids ~w(
    28669, 23937, 23870, 27095, 27413, 23966,
    23872, 26286, 16615, 28736, 23827, 26901,
    27096, 32362, 23940, 29535, 27365, 28764,
    23675, 23939, 23869, 23970, 28627, 23932
  )

  @educ_nat "ministere-de-l-education-nationale"
  @ens_sup "ministere-de-l-enseignement-superieur"
  @solidarite "ministere-charge-de-la-solidarite"
  @sports "ministere-de-la-jeunesse-des-sports-et-de-la-cohesion-sociale"

  def accepted_fiche?(fiche) do
    accessible_vae = xpath(fiche, ~x"./SI_JURY_VAE/text()"s) == "Oui"

    intitule = xpath(fiche, ~x"./INTITULE/text()"s) |> String.downcase()
    ignored_intitule = @ignored_fiche_intitules
      |> Enum.any?(&String.starts_with?(intitule, String.downcase(&1)))

    accessible_vae && !ignored_intitule

    # test = fiche
    # |> xpath(~x"./NUMERO_FICHE/text()"s)
    # |> String.replace_prefix("RNCP", "")
    # |> String.equivalent?("18704")

    # if test do
    #   IO.inspect("##############")
    #   IO.inspect("VAE? #{accessible_vae}")
    #   IO.inspect("Ignoré ? #{ignored_intitule}")
    #   IO.inspect("Donc : #{accessible_vae && !ignored_intitule}")
    #   IO.inspect("##############")
    # end
    # test
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
      is_custom_rncp = rncp_id in ["4505"]
      if is_educ_nat && (is_ignored_acronym || is_custom_rncp)  do
        FileLogger.log_into_file("men_rejected.csv", [rncp_id, acronym, label, is_rncp_active])
        true
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
    is_in_custom_list = rncp_id in ["4877", "4875", "34825", "34828", "35044"]

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
    rncp_id: "4877",
    romes: romes
  } = data) do
    Map.merge(data, %{romes: romes ++ [Repo.get_by(Rome, code: "M1203")]})
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