defmodule Vae.Mailer.FileExtractor do
  @type path :: String.t()

  @doc "Extract data"
  @callback extract(path(), List.t()) :: [Vae.Mailer.Email.t()]
end
