defmodule Vae.PowMailer do
  require Logger

  @moduledoc false
  # use Pow.Phoenix.Mailer
  # use Swoosh.Mailer, otp_app: :vae

  # import Swoosh.Email

  # use Swoosh.Mailer, otp_app: :vae

  # use Phoenix.Swoosh,
  #   view: Vae.EmailView,
  #   layout: {Vae.EmailView, :layout}

  # alias Swoosh.Email
  # alias Vae.{JobSeeker, User}

  # @config Application.get_env(:vae, Vae.Mailer)
  # @override_to System.get_env("DEV_EMAILS")

  def cast(email) do
    Vae.Mailer.build_email(:template, email.from, email.to)
    # %Email{}
    # |> from({"My App", "myapp@example.com"})
    # |> to({"", email.user.email})
    # |> subject(email.subject)
    # |> text_body(email.text)
    # |> html_body(email.html)
  end

  def process(email), do: Vae.Mailer.send(email)

  # def process(email), do: deliver(email)

end
