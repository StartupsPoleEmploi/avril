defmodule Vae.Authorities.Rncp.CustomRules do
  require Logger
  alias Vae.{Certifier, Certification, Repo}
  import Ecto.Query

  @ignored_certifier_slugs ~w(
    universite-de-nouvelle-caledonie
    universite-de-la-polynesie-francaise
  )

  @ignored_certifications [
    "Un des meilleurs ouvriers de France"
  ]

  @ignored_acronyms_for_educ_nat [
    "CQP",
    "DEUST",
    "DUT",
    "MASTER",
    "Licence Professionnelle",
    "Titre ingénieur",
  ]

  @overrides %{
    "Conservatoire national des arts et métiers (CNAM)" => "CNAM",
    "MINISTERE DE L'EDUCATION NATIONALE ET DE LA JEUNESSE" => "Ministère de l'Education Nationale",
    "MINISTERE CHARGE DES AFFAIRES SOCIALES" => "Ministère des affaires sociales et de la santé",
    "Ministère chargé de la santé " => "Ministère des affaires sociales et de la santé",
    "Ministère chargé de l'Emploi" => "Ministère du travail",
    "Ministère du Travail - Délégation Générale à l'Emploi et à la Formation Professionnelle (DGEFP)" => "Ministère du travail",
    "Ministère chargé de l'enseignement supérieur" => "Ministère de l'Education Nationale",
    "Ministère chargé des sports et de la jeunesse" => "Ministère de la jeunesse, des sports et de la cohésion sociale",
    "Ministère de l'Education nationale et de la jeunesse" => "Ministère de l'Education Nationale",
    "Ministère de l'Enseignement Supérieur" => "Ministère de l'Education Nationale",
    "Ministère de l’enseignement supérieur, de la recherche et de l’innovation" => "Ministère de l'Education Nationale",
    "Ministère de la Défense" => "Ministère des Armées",
    "Ministère de l'agriculture et de la pêche" => "Ministère chargé de l'agriculture",
  }

  def buildable_certifier?(slug) do
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

  def certifier_rncp_override(name) do
    case Enum.find(@overrides, fn {k, _v} ->
      String.starts_with?(Vae.String.parameterize(name), Vae.String.parameterize(k))
    end) do
      {_k, val} -> val
      nil -> name
    end
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
end