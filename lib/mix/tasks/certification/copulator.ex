defmodule Mix.Tasks.Certification.Copulator do
  use Mix.Task

  import SweetXml
  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Rome
  alias Vae.Certification
  alias Vae.Certifier

  @allowed_authorities [
    "MINISTERE DE L'EDUCATION NATIONALE",
    "Ministère chargé de l'enseignement supérieur",
    "MINISTERE CHARGE DES AFFAIRES SOCIALES",
    "MINISTERE CHARGE DES AFFAIRES SOCIALES - Direction générale de la cohésion sociale (DGCS)",
    "MINISTERE CHARGE DE LA SANTE DIRECTION GENERALE DE LA SANTE (DGS)",
    "Ministère de la santé - DIRECTION DE L'HOSPITALISATION ET DE L'ORGANISATION DES SOINS (DHOS)",
    "Ministère chargé de l'Emploi",
    "Ministère chargé des sports et de la jeunesse"
  ]

  def run(_args) do
    ensure_started(Vae.Repo, [])

    # Chunk
    File.stream!("priv/fixtures/csv/rome_certifications_2.csv")
    |> CSV.decode!()
    |> Enum.chunk(10, 10, [])
    |> Enum.map(fn chunk ->
      chunk
      |> Enum.map(fn [rome] ->
        Task.async(fn -> process(rome) end)
      end)
      |> Enum.map(&Task.await(&1, 600_000))
      |> Enum.each(&IO.inspect/1)
    end)

    #    [1,2,3] |> Stream.map(&Task.async(Test, :job, [&1])) |> Enum.map(&Task.await(&1)

    # No limit !
    #    File.stream!("priv/fixtures/csv/rome_certifications.csv")
    #    |> CSV.decode!
    #    |> Enum.map(fn [rome] ->
    #         Task.async(fn -> process(rome) end) end)
    #    |> Enum.map(&Task.await(&1, 600000))
    #    |> Enum.each(&IO.inspect/1)
  end

  def process(rome_code) do
    with rome <- Repo.get_by!(Rome, code: rome_code),
         {:ok, files} <- :file.list_dir('priv/fixtures') do
      files
      |> Enum.filter(fn file -> !File.dir?("priv/fixtures/#{file}") end)
      |> Enum.each(fn file ->
        Mix.shell().info("Fichier: #{file}")

        with {:ok, content} <- File.read("priv/fixtures/#{file}") do
          #             |> filter_by_up_to_date
          content
          |> read
          |> filter_by_rome_code(rome.code)
          |> filter_by_active
          |> filter_by_allowed_ministries
          |> filter_by_allowed_levels
          |> remove_others_than_bts_from_college_ministry
          |> convert
          |> Enum.each(&insert(&1, rome))
        else
          err -> Mix.shell().error(err)
        end
      end)
    end
  end

  def read(xml) do
    xml
    |> xpath(~x"//FICHES/FICHE"l)
  end

  def filter_by_rome_code(cards, rome_code) do
    cards
    |> Enum.filter(fn card ->
      card
      |> xpath(~x"./CODES_ROME/ROME/CODE/text()"sl)
      |> Enum.any?(&(&1 == rome_code))
    end)
  end

  def filter_by_active(cards) do
    cards
    |> Enum.filter(fn card ->
      card |> xpath(~x"./ETAT_FICHE/ID/text()"i) == 1 and
        card |> xpath(~x"./ACTIF/text()"s) == "Oui"
    end)
  end

  def filter_by_up_to_date(cards) do
    cards
    |> Enum.filter(fn card ->
      card
      |> xpath(~x"./NOUVELLE_CERTIFICATION"o) == nil
    end)
  end

  def filter_by_allowed_ministries(cards) do
    cards
    |> Enum.filter(fn card ->
      card
      |> get_allowed_authority_map
      |> MapSet.size() > 0
    end)
  end

  def filter_by_allowed_levels(cards) do
    cards
    |> Enum.filter(fn card ->
      # TODO: Fix level list
      Enum.member?(
        ["9", "10", "11"],
        card
        |> xpath(~x"./NOMENCLATURE_69/ID/text()"s)
      )
    end)
  end

  def remove_others_than_bts_from_college_ministry(cards) do
    cards
    |> Enum.filter(fn card ->
      card
      |> get_allowed_authority_map
      |> MapSet.size()
      |> case do
        size when size > 1 ->
          true

        _ ->
          cond do
            Enum.member?(
              card |> xpath(~x"./AUTORITES_RESPONSABLES/AUTORITE_RESPONSABLE/INTITULE/text()"sl),
              "Ministère chargé de l'enseignement supérieur"
            ) and card |> xpath(~x"./ABREGE/CODE/text()"s) != "BTS" ->
              false

            true ->
              true
          end
      end
    end)
  end

  def convert(cards) do
    Mix.shell().info("Found #{length(cards)} cards")

    cards
    |> Enum.map(fn card ->
      %{
        certifier:
          card
          |> xpath(~x"./AUTORITES_RESPONSABLES/AUTORITE_RESPONSABLE/INTITULE/text()"sl)
          |> MapSet.new()
          |> MapSet.intersection(MapSet.new(@allowed_authorities)),
        certification: %{
          label: card |> xpath(~x"./INTITULE/text()"s),
          acronym: card |> xpath(~x"./ABREGE/CODE/text()"s),
          level: card |> xpath(~x"./NOMENCLATURE_69/NIVEAU/text()"s) |> map_level,
          rncp_id: card |> xpath(~x"./IDENTIFIANT_EXTERNE/text()"s)
        }
      }
    end)
  end

  defp get_allowed_authority_map(card) do
    card
    |> xpath(~x"./AUTORITES_RESPONSABLES/AUTORITE_RESPONSABLE/INTITULE/text()"sl)
    |> MapSet.new()
    |> MapSet.intersection(MapSet.new(@allowed_authorities))
  end

  defp map_level(level) do
    case level do
      "I" -> 1
      "II" -> 2
      "III" -> 3
      "IV" -> 4
      "V" -> 5
      _ -> 6
    end
  end

  def insert(%{certifier: certifier, certification: certification}, rome) do
    with {:ok, mapped_name} <-
           map_to_certifier(certifier)
           |> map_to_certifier_entity,
         certifier <- Repo.get_by!(Certifier, name: mapped_name) |> Repo.preload(:delegates) do
      Mix.shell().info(
        "Insert #{certification.label} with #{rome.code} rome and certifier #{certifier.id}"
      )

      certification = get_or_insert_certification(certification)

      certification
      |> Repo.preload(:romes)
      |> Repo.preload(:certifiers)
      |> Repo.preload(:delegates)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:romes, [
        rome | certification |> Ecto.assoc(:romes) |> Repo.all()
      ])
      |> Ecto.Changeset.put_assoc(:certifiers, [
        certifier | certification |> Ecto.assoc(:certifiers) |> Repo.all()
      ])
      |> Ecto.Changeset.put_assoc(:delegates, certifier.delegates)
      |> Repo.update!()

      Mix.shell().info("#{certification.label} inserted")
    else
      err -> Mix.shell().error(err)
    end
  end

  defp get_or_insert_certification(certification) do
    Repo.get_by(Certification, label: certification.label) ||
      %Certification{}
      |> Certification.changeset(certification)
      |> Repo.insert!(on_conflict: [set: [label: certification.label]], conflict_target: :label)
  end

  def map_to_certifier(certifiers) do
    @allowed_authorities
    |> Enum.find(&Enum.member?(certifiers, &1))
  end

  # TODO: move guard clauses to macro
  def map_to_certifier_entity(authority)
      when authority == "MINISTERE CHARGE DE LA SANTE DIRECTION GENERALE DE LA SANTE (DGS)" or
             authority ==
               "Ministère de la santé - DIRECTION DE L'HOSPITALISATION ET DE L'ORGANISATION DES SOINS (DHOS)" or
             authority == "MINISTERE CHARGE DES AFFAIRES SOCIALES" or
             authority ==
               "MINISTERE CHARGE DES AFFAIRES SOCIALES - Direction générale de la cohésion sociale (DGCS)",
      do: {:ok, "Ministère des affaires sociales et de la santé"}

  def map_to_certifier_entity(authority)
      when authority == "MINISTERE DE L'EDUCATION NATIONALE" or
             authority == "Ministère chargé de l'enseignement supérieur",
      do: {:ok, "Ministère de l'Education Nationale"}

  def map_to_certifier_entity(authority) when authority == "Ministère chargé de l'Emploi",
    do:
      {:ok,
       "Ministère du travail de l'emploi de la formation professionnelle et du dialogue social"}

  def map_to_certifier_entity(authority)
      when authority == "Ministère chargé des sports et de la jeunesse",
      do: {:ok, "Ministère de la jeunesse, des sports et de la cohésion sociale"}

  def map_to_certifier_entity(code), do: {:error, "Unknown ministry code: #{code}"}
end
