defmodule Mix.Tasks.RncpUpdate do
  use Mix.Task

  require Logger
  import Ecto.Query
  alias Vae.{Certification, Certifier, Delegate, Rome, Repo, UserApplication}

  import SweetXml

  @new_certifiers [
    "Ministère de l'intérieur",
    "Ministère de la transition écologique et solidarité",
    "Ministère de l'agriculture et de la pêche"
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
      &Vae.Authorities.Rncp.FicheHandler.fiche_to_certification(&1)
    )

    build_and_transform_stream(
      options[:filename],
      &Vae.Authorities.Rncp.FicheHandler.move_applications_if_inactive_and_set_newer_certification(&1, [interactive: options[:interactive]])
    )

    clean_avril_data()
  end

  defp prepare_avril_data() do
    Vae.Authorities.Rncp.AuthorityMatcher.clear_log_file()

    Logger.info("Update slugs")
    Enum.each([Certifier, Delegate], fn klass ->
      Repo.all(klass)
      |> Enum.each(fn %klass{} = c ->
        klass.changeset(c) |> Repo.update()
      end)
    end)

    Logger.info("Make all certifications inactive")
    Repo.update_all(Certification, set: [is_active: false])

    Logger.info("Create static certifiers")
    Enum.each(@new_certifiers, fn c ->
      Repo.get_by(Certifier, slug: Vae.String.parameterize(c)) ||
      Vae.Authorities.Rncp.FicheHandler.create_certifier_and_maybe_delegate(c)
    end)
  end

  defp clean_avril_data() do
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
    |> Stream.filter(fn {_, fiche} ->
      !String.starts_with?(xpath(fiche, ~x"./INTITULE/text()"s), "CQP")
    end)
    |> Stream.each(fn {_, fiche} -> transform.(fiche) end)
    |> Stream.run()
  end
end
