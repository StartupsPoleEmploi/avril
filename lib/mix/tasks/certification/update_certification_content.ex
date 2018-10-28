defmodule Mix.Tasks.UpdateCertificationContent do
  use Mix.Task

  import SweetXml
  import Mix.Ecto
  import Ecto.Query

  alias Vae.Repo
  alias Vae.Certification

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:poison)

    Path.wildcard("priv/fixtures/export_fiches_cncp_2018-09-19/*.xml")
    |> Enum.each(fn file ->
      Mix.shell().info("Fichier #{Path.basename(file)}")

      case File.read(file) do
        {:ok, content} -> update_certification(content)
        {:error, msg} -> Mix.shell().error(msg)
      end
    end)
  end

  defp update_certification(content) do
    certifications = Repo.all(Certification)

    content
    |> read
    |> Enum.map(fn card ->
      rncp_id = card |> xpath(~x"./IDENTIFIANT_EXTERNE/text()"s)

      Enum.filter(certifications, fn %Certification{rncp_id: certification_rncp_id} ->
        rncp_id == certification_rncp_id
      end)
      |> case do
        [] ->
          true

        [certification | []] ->
          label = get_label(card)
          description = "#{get_activities(card)} #{get_capacities(card)}"

          certification
          |> Ecto.Changeset.change(%{
            label: label,
            description: description
          })
          |> Repo.update!()

          Mix.shell().info("#{certification.label} updated")

        [certification | _] ->
          Mix.shell().error("Too many certifications with the same rncp id: #{certification.id}")
      end
    end)
  end

  defp read(xml) do
    xml
    |> xpath(~x"//FICHES/FICHE"l)
  end

  defp get_label(card), do: get_text(card, "./INTITULE")
  defp get_activities(card), do: get_text(card, "./ACTIVITES_VISEES")
  defp get_capacities(card), do: get_text(card, "./CAPACITES_ATTESTEES")

  defp get_text(card, path) do
    card
    |> xpath(~x"#{path}/text()"s)
    |> String.replace("\n", "")
    |> String.replace("<b>", "")
    |> String.replace("</b>", "")
    |> String.replace("<i>", "")
    |> String.replace("</i>", "")
  end
end
