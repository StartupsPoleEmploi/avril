defmodule Mix.Tasks.AddCciCertifications do
  require Logger
  use Mix.Task

  import Ecto.Query
  import SweetXml

  alias Vae.{Certification, Certifier, Delegate}
  alias Vae.{Places, Repo}

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    Logger.info("Start import CCI certifications")

    certifiers =
      from(
        c in Certifier,
        where: like(c.name, "CCI%")
      )
      |> Repo.all()
      |> Enum.map(& &1.id)

    File.stream!("priv/fixtures/cci_delegates.csv")
    |> extract_cci_delegates(certifiers)
    |> build_delegate_changesets()
    |> insert!()

    extract_certifications()
    |> build_certifications(certifiers)
    |> build_certification_changesets()
    |> insert!()
  end

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
      |> Delegate.changeset(delegate)
    end)
  end

  def insert!(changesets) do
    Enum.map(changesets, fn changeset ->
      Repo.insert!(changeset)
    end)
  end

  def extract_certifications() do
    File.stream!("priv/rncp_rs_2020_03_03.xml")
    |> SweetXml.stream_tags(:FICHE)
    |> Stream.filter(fn {_, doc} ->
      "CCI FRANCE" ==
        doc
        |> xpath(~x"//CERTIFICATEURS/NOM_CERTIFICATEUR/text()"s)
    end)
    |> Stream.map(fn {_, doc} ->
      SweetXml.xmap(
        doc,
        label: ~x"./INTITULE/text()"s,
        acronym: ~x"./ABREGE/CODE/text()"s,
        activities: ~x"./ACTIVITES_VISEES/text()"s,
        abilities: ~x"./CAPACITES_ATTESTEES/text()"s,
        rncp_id:
          ~x"./NUMERO_FICHE/text()"s
          |> transform_by(fn s -> String.slice(s, 4..String.length(s)) end)
      )
    end)
    |> Stream.uniq_by(fn c -> c.rncp_id end)
    |> Enum.to_list()
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
