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
    Vae.Mailer.build_email(subject_to_template(email.subject), :avril, email.user, Map.merge(%{
      subject: email.subject,
      name: Vae.User.fullname(email.user)
    }, Enum.into(email.assigns, %{})))
  end

  def process(email), do: Vae.Mailer.send(email)

  defp subject_to_template(subject) do
    case subject do
      "Confirm your email address" -> "user/confirmation.html"
      "Reset password link" -> "user/password.html"
    end
  end
end
