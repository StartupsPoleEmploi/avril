defmodule Mix.Tasks.RncpUpdate do
  use Mix.Task

  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Repo}
  alias Vae.Authorities.Rncp.{CustomRules, FicheHandler, FileLogger}

  @static_certifiers [
    # "Ministère chargé de la Culture",
    # "Ministère de l'Intérieur",
    "Ministère de l'Enseignement supérieur",
    "Ministère chargé de la solidarité",
    "Direction de l'hospitalisation et de l'organisation des soins (DHOS)"
  ]

  @static_certifiers_with_delegate [
    "Université de Paris",
    "Université Paris-Saclay",
    "Université de Corse - Pasquale Paoli",
    "Université de Paris 8 | Vincennes",
    "Université Pierre et Marie Curie - Paris 6",
    "Université Paris-Est-Créteil-Val-de-Marne",
    "Université Paris-Est Marne-la-Vallée (UPEM)",
    "Université de Cergy-Pontoise",
    "Université PSL (Paris, Sciences & Lettres)",
    "Université Paris 2 Panthéon-Assas",
    "Université Paris Nanterre",
    "Université Paris Lumières",
    "Université Paris 1 Panthéon-Sorbonne",
    "Université Paris-Dauphine - PSL",
    "Université Côte d'Azur",
    "Aix-Marseille Université",
    "Université Paul Valéry"
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
    FileLogger.reinitialize_log_file("matches.csv", ~w(class input found score))
    FileLogger.reinitialize_log_file("men_rejected.csv", ~w(rncp_id acronym label is_active))
    make_all_certifications_inactive()
    update_all_slugs()
    store_former_certification_ids()
    create_static_certifiers()
    attach_asp_to_dhos()
  end

  def clean_avril_data() do
    # IO.gets("On clean ? Vérifions id_rncp 4877 d'abord")
    CustomRules.match_cci_former_certifiers()
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
    |> Enum.each(&FicheHandler.match_or_build_certifier(%{name: &1}, tolerance: 1, build: :force))

    @static_certifiers_with_delegate
    |> Enum.each(&FicheHandler.match_or_build_certifier(%{name: &1}, tolerance: 0.99, with_delegate: true, build: :force))
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
    |> Repo.preload([delegates: :certifiers])
    |> Enum.each(fn c ->
      IO.inspect("Deleting certifier #{c.name} ...")
      case %Certifier{id: id, name: name} = c do
        %Certifier{delegates: [%Delegate{name: dname, certifiers: [%Certifier{id: cid}]}]} when id == cid and name == dname ->
          IO.inspect("... and delegate")
          Enum.each(c.delegates, &(Repo.delete(&1)))
        _ -> nil
      end
      Repo.delete(c)
    end)
  end

  defp build_and_transform_stream(filename, transform) do
    File.stream!(filename)
    |> SweetXml.stream_tags(:FICHE, discard: [:FICHE])
    |> Stream.filter(fn {_, fiche} -> CustomRules.accepted_fiche?(fiche) end)
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
