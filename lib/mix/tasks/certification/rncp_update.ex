defmodule Mix.Tasks.RncpUpdate do
  require Logger
  use Mix.Task

  import SweetXml
  import Ecto.Query

  alias Vae.{Certification, Certifier, Rome, Repo, UserApplication}

  Logger.configure(truncate: :infinity)

  # {:ok, _} = Application.ensure_all_started(:vae)
  # @all_certifiers Repo.all(Certifier)

  @ignore_missing_certifiers [
    # "Université Nice Sophia Antipolis",
    # "LYCEE POLYVALENT CHAPTAL",
    # "Ecole Camondo (Paris)",
    # "Commission paritaire nationale de l'emploi et de la formation du spectacle vivant (CPNEF-SV) - Association de gestion de la commission paritaire nationale de l’emploi et de la formation du spectacle vivant",
    # "Commissions paritaires nationales de l’emploi conjointes du bâtiment et des travaux publics (CPNE conjointes du BTP) - Fédération française du bâtiment (FFB)"
  ]

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    Logger.info("Start update RNCP")

    # Logger.info("Make all inactive")
    # Repo.update_all(Certification, set: [is_active: false])

    filename = "rncp-2020-06-19.xml"
    # filename = "rncp-test.xml"
    certifiers_filename = "certifiers.csv"

    Logger.info("Parse RNCP #{filename}")
    # build_and_transform_stream(filename,
    #   &get_missing_certifiers/1
    # )
    # |> List.flatten()
    # |> Enum.reduce(%{}, fn name, res ->
    #   Map.merge(res, %{name => (res[name] || 0) + 1})
    # end)
    # |> IO.inspect()
    # |> to_csv(certifiers_filename)
    # |> CSV.encode()
    # |> Enum.each(&IO.write(file, &1))

    build_and_transform_stream(filename,
      &fiche_to_certification/1
    )

    build_and_transform_stream(filename,
      &move_applications_if_inactive_and_set_newer_certification/1
    )
  end

  defp to_csv(map, filename) do
    File.write!("priv/#{filename}", "Certifier; Count\n" <> (Enum.map(map, fn {k, v} -> "#{String.replace(k, ";", ",")}; #{v}" end) |> Enum.join("\n")))
  end

  def build_and_transform_stream(filename, transform) do
    File.stream!("priv/#{filename}")
    |> SweetXml.stream_tags(:FICHE)
    |> Stream.filter(fn {_, fiche} ->
      !String.starts_with?(xpath(fiche, ~x"./INTITULE/text()"s), "CQP")
    end)
    |> Stream.map(fn {_, fiche} -> transform.(fiche) end)
    |> Enum.to_list()
  end

  def get_missing_certifiers(fiche) do
    SweetXml.xpath(fiche, ~x"./CERTIFICATEURS/CERTIFICATEUR"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./NOM_CERTIFICATEUR/text()"s) end)
      |> Enum.map(&name_to_certifier/1)
      |> Enum.filter(fn
        {:err, name} ->
          Logger.debug("Certifier not found: #{name}")
          true
        _ -> false
      end)
      |> Enum.map(fn {:err, name} -> name end)
  end

  def fiche_to_certification(fiche) do
    rncp_id = SweetXml.xpath(fiche, ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      String.replace_prefix(nb, "RNCP", "")
    end))

    Logger.info("Updating RNCP_ID: #{rncp_id}")

    romes = SweetXml.xpath(fiche, ~x"./CODES_ROME/ROME"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./CODE/text()"s) end)
      |> Enum.map(fn code -> Repo.get_by(Rome, code: code) end)

    certifiers = SweetXml.xpath(fiche, ~x"./CERTIFICATEURS/CERTIFICATEUR"l)
      |> Enum.map(fn node -> SweetXml.xpath(node, ~x"./NOM_CERTIFICATEUR/text()"s) end)
      |> Enum.map(&name_to_certifier/1)
      |> Enum.filter(fn
        %Certifier{} -> true
        {:err, name} ->
          if not Enum.member?(@ignore_missing_certifiers, name) do
            Logger.warn("#####################################")
            Logger.warn("# No certifier found for: \"#{name}\" ")
            Logger.warn("#####################################")
          end
          false
      end)
      |> Enum.uniq()

    if not Enum.empty?(certifiers) do
      SweetXml.xmap(fiche,
        label: ~x"./INTITULE/text()"s |> transform_by(&String.slice(&1, 0, 225)),
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
      |> insert_or_update_by_rncp_id()
    end
  end

  def certifier_rncp_override(name) do
    case name do
      "Conservatoire national des arts et métiers (CNAM)" -> "CNAM"
      "Ministère chargé de l'enseignement supérieur" -> "Ministère de l'Education Nationale"
      "Ministère de l'Enseignement Supérieur" -> "Ministère de l'Education Nationale"
      "MINISTERE DE L'EDUCATION NATIONALE ET DE LA JEUNESSE" -> "Ministère de l'Education Nationale"
      "Ministère de l'Education nationale et de la jeunesse" -> "Ministère de l'Education Nationale"
      "Ministère chargé de l'Emploi" -> "Ministère du travail"
      n -> n
    end
  end

  def name_to_certifier(name) do
    # case Enum.find(@all_certifiers, &(&1.slug == Vae.String.parameterize(certifier_rncp_override(name)))) do
    case Repo.get_by(Certifier, slug: Vae.String.parameterize(certifier_rncp_override(name))) do
      nil ->
        # {:err, name}
        %Certifier{}
        |> Certifier.changeset(%{name: name})
        |> Repo.insert!()
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
          IO.inspect(e)
          # id = IO.gets("Quel ID supprime-t-on ? ")
          # |> String.trim()
          # |> String.to_integer()

          # Repo.get(UserApplication, id) |> Repo.delete()
      end
    else
      err ->
        Logger.debug(inspect(err))

        # Logger.debug("Newer certification not found for: #{rncp_id}")
    end
  end
end
