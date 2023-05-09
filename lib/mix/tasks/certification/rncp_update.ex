defmodule Mix.Tasks.RncpUpdate do
  use Mix.Task

  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Repo}
  alias Vae.Authorities.Rncp.FileLogger

  @moduledoc """
  Update DB content with rncp xml file

  ## Examples
    mix RncpUpdate -f priv/rncp-2020-20-23.xml

  ## Command line options

  * `-f`, `--filename` - required - the XML source file
  """

  def run([]) do
    Logger.error("RNCP filename argument required. Ex: mix RncpUpdate -f priv/rncp-2020-08-03.xml")
  end

  def run(args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    {options, [], []} = OptionParser.parse(args,
      aliases: [f: :filename],
      strict: [filename: :string]
    )
    %{filename: filename} = options =
      Map.merge(%{import_date: Date.utc_today()}, Map.new(options))

    Logger.info("Start update RNCP with #{filename}")
    prepare_avril_data()

    Logger.info("Parsing fiches to certifications")
    # build_and_transform_stream(
    #   filename,
    #   &FicheHandler.fiche_to_certification(&1, options)
    # )

    # Logger.info("Linking old certifications with new ones")
    # build_and_transform_stream(
    #   filename,
    #   &FicheHandler.move_applications_if_inactive_and_set_newer_certification(&1)
    # )

    clean_avril_data(options)
  end

  def prepare_avril_data() do
    Logger.info("Reset log files")
    FileLogger.reinitialize_log_file("matches.csv", ~w(class input found score))
    FileLogger.reinitialize_log_file("men_rejected.csv", ~w(rncp_id acronym label is_active))
    FileLogger.reinitialize_log_file("inactive_date.csv", ~w(rncp_id acronym label))
    FileLogger.reinitialize_log_file("changes.log")
  end

  def clean_avril_data(%{import_date: import_date}) do
    # remove_certifiers_without_certifications()
    make_not_updated_certifications_inactive(import_date)
    update_search_indexes()
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
    {nb_updated, _} = from(c in Certification,
      where: c.last_rncp_import_date != ^import_date
    ) |> Repo.update_all(set: [is_active: false])
    Logger.info("#{nb_updated} certifications made inactive")
  end

  def update_search_indexes() do
    Logger.info("Update Search Index")
    Vae.Search.FullTextSearch.refresh_materialized_view()
  end
end
