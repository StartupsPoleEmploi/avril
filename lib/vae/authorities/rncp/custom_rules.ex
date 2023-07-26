defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Repo, Rome}
  alias Vae.Authorities.Rncp.FicheHandler

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
    "BUT",
    "MASTER",
    "Licence Professionnelle",
    "Titre ingénieur",
  ]

  @cci_certifications_rncp_ids ~w(
    11200 23827 23869 23872 23932
    23937 23939 23940 26901 27095
    27096 27365 27413 28669 28764
    29535 32362 34353 34928 34965
    34999 35001 35010 36395 36865
    35538 35202 36629 36123 36149
    36390 34716 19251 34654 37523
    36534 36141 36591 36022 34928
  )

  @wrong_educ_nat_certifiers ~w(
    230 367 2028 2514 2829 4495 4496 4500 4503 4505
    18363 25467 28557 34824 34827 34829 34862 36004
  )
  @missing_educ_nat_certifiers ~w(4875 34825 34826 34828 35044)

  @educ_nat "ministere-de-l-education-nationale"
  @ens_sup "ministere-de-l-enseignement-superieur"
  @solidarite "ministere-charge-de-la-solidarite"
  @sports "ministere-de-la-jeunesse-des-sports-et-de-la-cohesion-sociale"
  @sante "ministere-des-affaires-sociales-et-de-la-sante"
  @gobelins "gobelins-l-ecole-de-l-image"
  @agriculture "ministere-charge-de-l-agriculture"

  def accepted_fiche?(fiche_params) do
    accessible_vae = get_in(fiche_params, ["SI_JURY_VAE", "ACTIF"]) == "Oui"

    intitule = fiche_params["INTITULE"] |> String.downcase()

    ignored_intitule = @ignored_fiche_intitules
      |> Enum.any?(&String.starts_with?(intitule, String.downcase(&1)))

    acronym = get_in(fiche_params, ["ABREGE", "CODE"])
    ignored_acronym = acronym in @ignored_fiche_acronyms

    accessible_vae && !ignored_intitule && !ignored_acronym
  end

  def transform_certifiers(certifiers_or_changesets, fiche_params) do
    certifiers = Enum.map(certifiers_or_changesets, &FicheHandler.ensure_certifiers(&1))

    certifiers
    |> reject_educ_nat_certifiers(fiche_params)
    |> reject_agriculture_certifier(fiche_params)
    |> add_educ_nat_certifiers(fiche_params)
  end

  def reject_educ_nat_certifiers(certifiers, %{
    acronym: acronym,
    rncp_id: rncp_id,
  }) do
    Enum.reject(certifiers, fn %Certifier{slug: slug} ->
      is_educ_nat = slug == @educ_nat
      is_ignored_acronym = Enum.member?(@ignored_acronyms_for_educ_nat, acronym)
      is_custom_rncp = rncp_id in @wrong_educ_nat_certifiers
      is_already_sports = Enum.any?(certifiers, &(&1.slug == @sports))
      is_educ_nat && (is_ignored_acronym || is_custom_rncp || is_already_sports)
    end)
  end

  def reject_agriculture_certifier(certifiers, %{
    level: level
  }) do
    Enum.reject(certifiers, fn %Certifier{slug: slug} ->
      slug === @agriculture && level > 5
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

  # def custom_data_transformations(%{
  #   certifiers: [%Certifier{slug: @educ_nat} | _],
  #   end_of_rncp_validity: %Date{year: year, month: month}
  # } = data) when year == @current_year and month >= 7 do
  #   Map.merge(data, %{is_active: false})
  # end

  def custom_data_transformations(%{
    rncp_id: "23909"
  } = data) do
    Map.merge(data, %{acronym: "BATC"})
  end

  def custom_data_transformations(%{
    rncp_id: rncp_id
  } = data) when rncp_id in ["31181", "31182", "25471", "34595", "35864", "25522", "31519"] do
    Map.merge(data, %{
      certifiers: [Repo.get_by(Certifier, slug: @gobelins)]
    })
  end

  def custom_data_transformations(%{
    rncp_id: "28557"
  } = data) do
    Map.merge(data, %{
      certifiers: [Repo.get_by(Certifier, slug: @sports)]
    })
  end

  def custom_data_transformations(%{
    rncp_id: "37679"
  } = data) do
    Map.merge(data, %{
      certifiers: [Repo.get_by(Certifier, slug: @sante)]
    })
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

  # def custom_data_transformations(%{
  #   rncp_id: rncp_id,
  #   certifiers: [%Certifier{slug: "cci-france"} | _]
  # } = data) when rncp_id not in @cci_certifications_rncp_ids do
  #   Map.merge(data, %{is_active: false})
  # end

  def custom_data_transformations(data), do: data
end