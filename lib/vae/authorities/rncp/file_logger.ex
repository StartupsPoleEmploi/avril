defmodule Vae.Authorities.Rncp.FileLogger do
  require Logger

  @log_file "priv/matches.log"

  def clear_log_file() do
    Logger.info("Remove previous log file")
    File.rm(@log_file)
  end

  def log_into_file(content) do
    {:ok, file} = File.open(@log_file, [:append])
    IO.write(file, content)
    :ok = File.close(file)
  end
end