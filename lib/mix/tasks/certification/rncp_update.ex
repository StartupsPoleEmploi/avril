defmodule Mix.Tasks.RncpUpdate do
  use Mix.Task

  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Repo}
  alias Vae.Authorities.Rncp.{CustomRules, FicheHandler, FileLogger}

  @moduledoc """
  Update DB content with rncp xml file

  ## Examples
    mix RncpUpdate -f priv/rncp-2020-20-23.xml

  ## Command line options

  * `-f`, `--filename` - required - the XML source file
  * `-i`, `--interactive` - default: false - ask if user applications should be removed in case of doublon of former certification
  * `-x`, `--index` - default: env() == :prod - should algolia indexes be updated?
  """

  def run([]) do
    Logger.error("RNCP filename argument required. Ex: mix RncpUpdate -f priv/rncp-2020-08-03.xml")
  end

  def run(args) do
    System.put_env("ALGOLIA_SYNC", "disable")
    {:ok, _} = Application.ensure_all_started(:vae)

    {options, [], []} = OptionParser.parse(args,
      aliases: [f: :filename, i: :index],
      strict: [filename: :string, index: :boolean]
    )
    %{filename: filename} = options =
      Map.merge(%{import_date: Date.utc_today(), index: Mix.env() == :prod}, Map.new(options))

    Logger.info("Start update RNCP with #{filename}")
    prepare_avril_data()

    build_and_transform_stream(
      filename,
      &FicheHandler.fiche_to_certification(&1, options)
    )

    build_and_transform_stream(
      filename,
      &FicheHandler.move_applications_if_inactive_and_set_newer_certification(&1)
    )

    clean_avril_data(options)
  end

  def prepare_avril_data() do
    FileLogger.reinitialize_log_file("matches.csv", ~w(class input found score))
    FileLogger.reinitialize_log_file("men_rejected.csv", ~w(rncp_id acronym label is_active))
    FileLogger.reinitialize_log_file("inactive_date.csv", ~w(rncp_id acronym label))
    FileLogger.reinitialize_log_file("changes.log")
  end

  def clean_avril_data(%{index: index, import_date: import_date}) do
    remove_certifiers_without_certifications()
    make_not_updated_certifications_inactive(import_date)
    if index, do: update_search_indexes()
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
      case %Certifier{id: id, name: name} = c do
        %Certifier{delegates: [%Delegate{name: dname, certifiers: [%Certifier{id: cid}]}]} when id == cid and name == dname ->
          Enum.each(c.delegates, &(Repo.delete(&1)))
        _ -> nil
      end
      Repo.delete(c)
    end)
  end

  def make_not_updated_certifications_inactive(import_date) do
    Logger.info("Make not updated certifications inactive")
    from(c in Certification,
      where: c.last_rncp_import_date != ^import_date
    ) |> Repo.update_all(is_active: false)
  end

  defp build_and_transform_stream(filename, transform) do
    File.stream!(filename)
    |> SweetXml.stream_tags(:FICHE, discard: [:FICHE])
    |> Stream.filter(fn {_, fiche} -> CustomRules.accepted_fiche?(fiche) end)
    |> Stream.each(fn {_, fiche} -> transform.(fiche) end)
    |> Stream.run()
  end

  def update_search_indexes() do
    Logger.info("Update Algolia Indexes")
    Mix.Tasks.Search.Index.run(~w|-m Vae.Certification -m Vae.Delegate -c|)
  end
end
