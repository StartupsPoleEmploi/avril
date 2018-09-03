defmodule Vae.Mailer.Sender do
  @doc "Send email"
  @callback send(%Vae.Mailer.Email{}) :: %Vae.Mailer.Email{}
end
