defmodule Mix.Tasks.RncpUpdate do
  use Mix.Task

  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Repo}
  alias Vae.Authorities.Rncp.{CustomRules, FicheHandler, FileLogger}
  import SweetXml

  @static_certifiers [
    "Ministère chargé de la Culture",
    "Ministère de l'Intérieur",
    "Ministère de l'Enseignement supérieur",
    "Direction de l'hospitalisation et de l'organisation des soins (DHOS)"
  ]

  @static_certifiers_with_delegate [
    "Université Paris-Saclay",
    "Université de Corse - Pasquale Paoli",
    "Université de Paris 8 | Vincennes",
    "Université de Paris",
    "Université Pierre et Marie Curie - Paris 6",
    "Université Paris-Est Marne-la-Vallée (UPEM)",
    "Université de Cergy-Pontoise",
    "Université PSL (Paris, Sciences & Lettres)",
    "Université Paris 2 Panthéon-Assas",
    "Université Paris Ouest Nanterre la Défense"
  ]

  def run([]) do
    Logger.error("RNCP filename argument required. Ex: mix RncpUpdate -f priv/rncp-2020-08-03.xml")
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

  def prepare_avril_data() do
    FileLogger.clear_log_file()
    update_all_slugs()
    store_former_certification_ids()
    make_all_certifications_inactive()
    create_static_certifiers()
    attach_asp_to_dhos()
  end

  def clean_avril_data() do
    CustomRules.match_cci_former_certifiers()
    CustomRules.custom_acronym()
    CustomRules.deactivate_deamp()
    CustomRules.deactivate_all_bep()
    CustomRules.deactivate_culture_ministry_certifications()
    CustomRules.special_rules_for_educ_nat()
    CustomRules.associate_some_enseignement_superieur_to_education_nationale()
    remove_certifiers_without_certifications()
    clear_certifier_internal_notes()
  end

  defp update_all_slugs() do
    Logger.info("Update slugs")
    Enum.each([Delegate], fn klass ->
      Repo.all(klass)
      |> Enum.each(fn %klass{} = c ->
        klass.changeset(c) |> Repo.update()
      end)
    end)
  end

  def create_static_certifiers() do
    @static_certifiers
    |> Enum.each(&FicheHandler.match_or_build_certifier(&1, tolerance: 1, force_build: true))

    @static_certifiers_with_delegate
    |> Enum.each(&FicheHandler.match_or_build_certifier(&1, with_delegate: true, force_build: true))
  end

  def attach_asp_to_dhos() do
    asp = Repo.one(from d in Delegate, where: like(d.slug, "asp-%"))
    |> Repo.preload(:certifiers)
    dohs = Repo.get_by(Certifier, slug: "direction-de-l-hospitalisation-et-de-l-organisation-des-soins-dhos")

    Delegate.changeset(asp, %{
      certifiers: asp.certifiers ++ [dohs]
    }) |> Repo.update()
  end

  defp make_all_certifications_inactive() do
    Logger.info("Make all certifications inactive")
    Repo.update_all(Certification, set: [is_active: false])
  end

  def remove_certifiers_without_certifications() do
    Logger.info("Remove certifiers without active certifications")
    from(c in Certifier,
      left_join: a in assoc(c, :active_certifications),
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

  def store_former_certification_ids() do
    Logger.info("Store former certification ids")
    Repo.all(Certifier)
    |> Repo.preload(:certifications)
    |> Enum.each(fn c ->
      Certifier.changeset(c, %{
        internal_notes: Enum.map(c.certifications, &(&1.id)) |> Enum.join(",")
      })
      |> Repo.update()
    end)
  end

  def clear_certifier_internal_notes() do
    Logger.info("Clear certifier internal notes")
    Repo.update_all(Certifier, set: [internal_notes: nil])
  end
end
