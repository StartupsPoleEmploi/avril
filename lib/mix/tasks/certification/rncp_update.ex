defmodule Mix.Tasks.RncpUpdate do
  require Logger
  use Mix.Task

  import Ecto.Query
  import SweetXml

  alias Vae.{Certification, Certifier, Delegate}
  alias Vae.{Places, Repo}

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)
    {:ok, _started} = Application.ensure_all_started(:poison)
    {:ok, _started} = Application.ensure_all_started(:hackney)

    Logger.info("Start update RNCP")

    Logger.info("Make all inactive")
    Repo.update_all(Certification, set: [is_active: false])

    Logger.info("Parse RNCP")
    # File.stream!("priv/rncp_2019_11_local.xml")
    # File.stream!("priv/rncp-2020-06-19.xml")
    File.stream!("priv/rncp-test.xml")
    |> SweetXml.stream_tags(:FICHE)
    |> Stream.map(fn {_, fiche} ->
      fiche
      |> fiche_to_certification_fields()
    end)
    |> Enum.to_list()
    |> IO.inspect()
  end

  def fiche_to_certification_fields(fiche) do

    # romes = SweetXml.xpath(fiche, ~x"./CODES_ROME/"l) |> IO.inspect()

    # Rome / Certificateur

    SweetXml.xmap(fiche, %{
      rncp_id: ~x"./NUMERO_FICHE/text()"s
      # rncp_id: ~x"./NUMERO_FICHE/text()"s |> transform_by(fn nb ->
      #   String.replace_prefix(nb, "RNCP", "")
      # end)
      # label: ~x"./INTITULE/text()"s,
      # acronym: ~x"./ABREGE/CODE/text()"s,
      # activities: ~x"./ACTIVITES_VISEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      # abilities: ~x"./CAPACITES_ATTESTEES/text()"s |> transform_by(&HtmlEntities.decode/1),
      # activity_area: ~x"./SECTEURS_ACTIVITE/text()"s,
      # accessible_job_type: ~x"./TYPE_EMPLOI_ACCESSIBLES/text()"s,
      # level: ~x"./NOMENCLATURE_EUROPE/NIVEAU/text()"s |> transform_by(fn l ->
      #   l
      #   |> String.replace_prefix("NIV", "")
      #   |> String.to_integer()
      # end),
      # is_active: ~x"./ACTIF/text()"s |> transform_by(fn t ->
      #   case t do
      #     "Oui" -> true
      #     _ -> false
      #   end
      # end)
    })
  end

  def insert_or_update_by_rncp_id(%{rncp_id: rncp_id} = fields) do
    Repo.get_by(Certification, rncp_id: rncp_id)
    |> case do
      nil -> %Certification{rncp_id: rncp_id}
      %Certification{} = c -> c
    end
    |> Certification.changeset(fields)
    |> Repo.insert_or_update()
  end



  def extract_certifications() do
  end

  #   certifiers =
  #     from(
  #       c in Certifier,
  #       where: like(c.name, "CCI%")
  #     )
  #     |> Repo.all()
  #     |> Enum.map(& &1.id)

  #   File.stream!("priv/fixtures/cci_delegates.csv")
  #   |> extract_cci_delegates(certifiers)
  #   |> build_delegate_changesets()
  #   |> insert!()

  #   extract_certifications()
  #   |> build_certifications(certifiers)
  #   |> build_certification_changesets()
  #   |> insert!()

  def extract_cci_delegates(res, certifiers) do
    res
    |> CSV.decode!(headers: true)
    |> Enum.map(fn %{
                     "Name" => name,
                     "Adresse_postale" => address,
                     "first_name" => first_name,
                     "last_name" => last_name,
                     "Mail" => email,
                     "Telephone" => phone
                   } ->
      %{
        name: name,
        address: address,
        geolocation: Places.get_geoloc_from_address(address),
        person_name: "#{first_name} #{last_name}",
        email: email,
        telephone: "0#{phone}",
        certifiers: certifiers
      }
    end)
  end

  def build_delegate_changesets(delegates) do
    Enum.map(delegates, fn delegate ->
      %Delegate{}
      |> Delegate.changeset_update(delegate)
    end)
  end

  def insert!(changesets) do
    Enum.map(changesets, fn changeset ->
      Repo.insert!(changeset)
    end)
  end


  def build_certifications(certifications, certifiers) do
    Enum.map(certifications, fn certification ->
      %{
        label: certification[:label],
        acronym: certification[:acronym],
        description: "#{certification[:activities]} #{certification[:abilities]}" |> get_text(),
        rncp_id: certification[:rncp_id],
        certifiers: certifiers
      }
    end)
  end

  def build_certification_changesets(certifications) do
    Enum.map(certifications, fn certification ->
      %Certification{}
      |> Certification.changeset(certification)
    end)
  end

  defp get_text(text) do
    text
    |> String.replace("\n", "")
    |> String.replace("<b>", "")
    |> String.replace("</b>", "")
    |> String.replace("<i>", "")
    |> String.replace("</i>", "")
  end
end
