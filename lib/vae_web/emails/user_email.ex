defmodule VaeWeb.UserEmail do
  require Logger
  alias Vae.URI
  alias VaeWeb.Mailer
  alias VaeWeb.Router.Helpers, as: Routes

  def reset_password(user, token, endpoint \\ URI.endpoint()) do
    Mailer.build_email(
      "user/reset_password.html",
      :avril,
      user,
      %{
        name: Vae.Account.fullname(user),
        url: Routes.reset_password_url(endpoint, :edit, token)
      }
    )
  end
end
