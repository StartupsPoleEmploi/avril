defmodule Vae.Mailer.FileExtractor do
  @type path :: String.t()
  @type job_seeker :: Map.t()

  @doc "Extract data"
  @callback extract(path()) :: [job_seeker()]
end
