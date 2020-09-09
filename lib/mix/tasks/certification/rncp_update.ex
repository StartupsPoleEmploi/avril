defmodule Mix.Tasks.RncpUpdate do
  require Logger
  use Mix.Task

  import SweetXml
  import Ecto.Query

  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    Logger.info("Start update RNCP")

    Logger.info("Make all inactive")
    Repo.update_all(Certification, set: [is_active: false])

    Logger.info("Parse RNCP")
    File.stream!("priv/rncp-2020-06-19.xml")
    # File.stream!("priv/rncp-test.xml")
    |> SweetXml.stream_tags(:FICHE)
    |> Stream.filter(fn {_, fiche} ->
      !String.starts_with?(xpath(fiche,~x"./INTITULE/text()"s), "CQP")
    end)
    |> Stream.map(fn {_, fiche} ->
      fiche
      |> fiche_to_certification_fields()
      |> insert_or_update_by_rncp_id()
    end)
    |> Enum.to_list()

    # File.stream!("priv/rncp-test.xml")
    File.stream!("priv/rncp-2020-06-19.xml")
    |> SweetXml.stream_tags(:FICHE)
    |> Stream.map(fn {_, fiche} ->
      fiche
      |> move_applications_if_inactive_and_set_newer_certification()
    end)
    |> Enum.to_list()
  end

  def fiche_to_certification_fields(fiche) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    Logger.info("Updating RNCP_ID: #{rncp_id}")

    romes = SweetXml.xpath(fiche, ~x"./CODES_ROME"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./ROME/CODE/text()"s) end)
      |> Enum.map(fn code -> Repo.get_by(Rome, code: code) end)

    certifiers = SweetXml.xpath(fiche, ~x"./CERTIFICATEURS"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./CERTIFICATEUR/NOM_CERTIFICATEUR/text()"s) end)
      |> Enum.map(&name_to_certifier/1)

    SweetXml.xmap(fiche,
      label: ~x"./INTITULE/text()"s,
      acronym: ~x"./ABREGE/CODE/text()"s,
      activities: ~x"./ACTIVITES_VISEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      abilities: ~x"./CAPACITES_ATTESTEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      activity_area: ~x"./SECTEURS_ACTIVITE/text()"s,
      accessible_job_type: ~x"./TYPE_EMPLOI_ACCESSIBLES/text()"s,
      level: ~x"./NOMENCLATURE_EUROPE/NIVEAU/text()"s |> transform_by(fn l ->
        l
        |> String.replace_prefix("NIV", "")
        |> Vae.Maybe.if(&Vae.String.is_present?/1, &String.to_integer/1)
      end),
      is_active: ~x"./ACTIF/text()"s |> transform_by(fn t ->
        case t do
          "Oui" -> true
          _ -> false
        end
      end)
    )
    |> Map.merge(%{
      rncp_id: rncp_id,
      romes: romes,
      certifiers: certifiers
    })
  end

  def certifier_rncp_override(name) do
    case name do
      "Ministère chargé de l'enseignement supérieur" -> "Ministère de l'Education Nationale"
      "Ministère chargé de l'Emploi" -> "Ministère du travail"
      n -> n
    end
  end

  def name_to_certifier(name) do
    case Repo.get_by(Certifier, slug: Vae.String.parameterize(certifier_rncp_override(name))) do
      nil ->
        Logger.warn("#####################################")
        Logger.warn("# No certifier found for #{name} ")
        Logger.warn("#####################################")
      %Certifier{} = c -> c
    end
  end

  def insert_or_update_by_rncp_id(%{rncp_id: rncp_id} = fields) do
    Repo.get_by(Certification, rncp_id: rncp_id)
    |> case do
      nil -> %Certification{rncp_id: rncp_id}
      %Certification{} = c -> c
    end
    |> Repo.preload([:certifiers, :romes])
    |> Certification.changeset(fields)
    |> Repo.insert_or_update()
  end

  def move_applications_if_inactive_and_set_newer_certification(fiche) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    with(
      %Certification{id: certification_id} = certification <-
        Repo.get_by(Certification, rncp_id: rncp_id) |> Repo.preload([:newer_certification]),
      newer_rncp_id when not is_nil(newer_rncp_id) <-
        SweetXml.xpath(fiche, ~x"./NOUVELLE_CERTIFICATION/text()"s
          |> transform_by(fn nb ->
            String.replace_prefix(nb, "RNCP", "")
          end)),
      %Certification{id: newer_certification_id} = newer_certification <-
        Repo.get_by(Certification, rncp_id: newer_rncp_id),
      {:ok, _} <- Certification.changeset(certification, %{newer_certification: newer_certification}) |> Repo.update()
    ) do
      from(a in UserApplication,
        where: [certification_id: ^certification_id]
      ) |> Repo.update_all(set: [certification_id: newer_certification_id])
    else
      err ->
        IO.inspect(err)
        Logger.debug("Newer certification not found for: #{rncp_id}")
    end
  end
end
