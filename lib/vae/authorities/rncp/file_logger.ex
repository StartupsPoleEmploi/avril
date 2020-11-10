defmodule Vae.Authorities.Rncp.FileLogger do
  require Logger

  alias Vae.Certification

  @separator ";"

  def reinitialize_log_file(log_file, columns \\ nil) do
    Logger.info("Remove previous log file #{log_file}")
    File.rm("priv/#{log_file}")
    if not is_nil(columns), do: log_into_file(log_file, columns)
  end

  def log_into_file(log_file, row) when is_list(row) do
    log_into_file(log_file, "#{Enum.join(row, @separator)}\n")
  end

  def log_into_file(log_file, content) when is_binary(content) do
    {:ok, file} = File.open("priv/#{log_file}", [:append, :utf8])
    IO.write(file, content)
    :ok = File.close(file)
  end

  def log_changeset(%Ecto.Changeset{changes: changes, data: %struct{id: id}} = changeset) when changes != %{} do
    changes = changes_ignore_keys(changes, struct)
    if changes != %{} do
      log_into_file("changes.log", """
        Type: #{struct}
        ID: #{id}
        Changes : #{inspect(changes)}
      """)
    end
    changeset
  end
  def log_changeset(c), do: c

  defp changes_ignore_keys(changes, Certification) do
    Enum.reduce(~w(abilities activity_area)a, changes, fn key, acc ->
      Map.delete(acc, key)
    end)
  end

  defp changes_ignore_keys(changes, _), do: changes
end