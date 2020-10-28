defmodule Vae.Authorities.Rncp.FileLogger do
  require Logger

  def clear_log_file(log_file) do
    Logger.info("Remove previous log file")
    File.rm("priv/#{log_file}")
  end

  def log_into_file(log_file, content) do
    {:ok, file} = File.open("priv/#{log_file}", [:append])
    IO.write(file, content)
    :ok = File.close(file)
  end
end