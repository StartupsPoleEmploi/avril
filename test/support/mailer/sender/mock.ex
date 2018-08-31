defmodule Vae.Mailer.Sender.Mock do
  @behaviour Vae.Mailer.Sender

  alias Vae.Mailer.Email

  def send(email), do: [email]
end
