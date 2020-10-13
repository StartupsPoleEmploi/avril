defmodule Mix.Tasks.RncpUpdate do
  use Mix.Task

  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Repo}
  alias Vae.Authorities.Rncp.{CustomRules, FicheHandler, FileLogger}
  import SweetXml

  @static_certifiers [
    "Ministère chargé de la Culture",
    "Ministère de le l'Intérieur"
  ]

  def run([]) do
    Logger.error("RNCP filname argument required. Ex: mix RncpUpdate -f priv/rncp-2020-08-03.xml")
  end

  def run(args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    {options, [], []} = OptionParser.parse(args, aliases: [i: :interactive, f: :filename], strict: [filename: :string, interactive: :boolean])

    Logger.info("Start update RNCP with #{options[:filename]}")
    prepare_avril_data()

    build_and_transform_stream(
      options[:filename],
      &FicheHandler.fiche_to_certification(&1)
    )

    build_and_transform_stream(
      options[:filename],
      &FicheHandler.move_applications_if_inactive_and_set_newer_certification(&1, [interactive: options[:interactive]])
    )

    clean_avril_data()
  end

  defp prepare_avril_data() do
    FileLogger.clear_log_file()
    update_all_slugs()
    make_all_certifications_inactive()
    create_static_certifiers()
  end

  defp clean_avril_data() do
    CustomRules.custom_acronym()
    CustomRules.deactivate_deamp()
    CustomRules.deactivate_all_bep()
    CustomRules.deactivate_culture_ministry()
    remove_certifiers_without_certifications()
  end

  defp update_all_slugs() do
    Logger.info("Update slugs")
    Enum.each([Certifier, Delegate], fn klass ->
      Repo.all(klass)
      |> Enum.each(fn %klass{} = c ->
        klass.changeset(c) |> Repo.update()
      end)
    end)
  end

  defp create_static_certifiers() do
    @static_certifiers
    |> Enum.each(fn name ->
      case Repo.get_by(Certifier, slug: Vae.String.parameterize(name)) do
        %Certifier{} = c -> c
        nil ->
          Certifier.changeset(%Certifier{}, %{name: name})
          |> Repo.insert()
      end
    end)
  end

  defp make_all_certifications_inactive() do
    Logger.info("Make all certifications inactive")
    Repo.update_all(Certification, set: [is_active: false])
  end

  defp remove_certifiers_without_certifications() do
    Logger.info("Remove certifiers without certifications")
    from(c in Certifier,
      left_join: a in assoc(c, :certifications),
      group_by: c.id,
      having: count(a.id) == ^0
    )
    |> Repo.all()
    |> Enum.each(&Repo.delete(&1))
  end

  defp build_and_transform_stream(filename, transform) do
    File.stream!(filename)
    |> SweetXml.stream_tags(:FICHE, discard: [:FICHE])
    |> Stream.reject(fn {_, fiche} ->
      CustomRules.rejected_fiche?(xpath(fiche, ~x"./INTITULE/text()"s))
    end)
    |> Stream.each(fn {_, fiche} -> transform.(fiche) end)
    |> Stream.run()
  end
end
