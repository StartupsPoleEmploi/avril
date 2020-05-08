defmodule VaeWeb.UserEmail do
  require Logger
  alias VaeWeb.Mailer
  alias VaeWeb.Endpoint
  alias VaeWeb.Router.Helpers, as: Routes

  def reset_password(user, token) do
    Mailer.build_email(
      "user/reset_password.html",
      :avril,
      user,
      %{
        name: Vae.Account.fullname(user),
        url: Routes.reset_password_url(Endpoint, :edit, token),
        subject:
          "Réinitialiser son mot de passe Avril, la VAE facile"
      }
    )
  end
end
