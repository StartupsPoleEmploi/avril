defmodule Vae.Authorities.Rncp.FileLogger do
  require Logger

  @separator ";"

  def reinitialize_log_file(log_file, columns) do
    Logger.info("Remove previous log file")
    File.rm("priv/#{log_file}")
    log_into_file(log_file, "#{Enum.join(columns, @separator)}\n")
  end

  def log_into_file(log_file, row) do
    {:ok, file} = File.open("priv/#{log_file}", [:append, :utf8])
    IO.write(file, "#{Enum.join(row, @separator)}\n")
    :ok = File.close(file)
  end
end