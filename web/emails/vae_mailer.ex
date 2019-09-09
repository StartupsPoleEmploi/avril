defmodule Vae.Mailer do
  use Swoosh.Mailer, otp_app: :vae
  use Phoenix.Swoosh,
    view: Vae.EmailView,
    layout: {Vae.LayoutView, :email}
  import Swoosh.Email

  @from_avril {
    Application.get_env(:vae, :mailjet)[:from_name],
    Application.get_env(:vae, :mailjet)[:from_email]
  }

  def from_avril(), do: @from_avril
end