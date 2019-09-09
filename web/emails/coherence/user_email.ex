Code.ensure_loaded Phoenix.Swoosh

defmodule Vae.Coherence.UserEmail do
  @moduledoc false
  use Phoenix.Swoosh, view: Vae.Coherence.EmailView, layout: {Vae.Coherence.LayoutView, :email}
  alias Swoosh.Email
  require Logger
  alias Coherence.Config
  import Vae.Gettext
  alias Vae.Mailer.Sender.Mailjet
  alias Vae.User

  def password(user, url) do
    user_email(
      "Réinitialisation du mot de passe sur Avril - la VAE facile",
      "password.html",
      user,
      %{url: url}
    )
    # %Email{}
    # |> from(Coherence.Config.email_from)
    # |> to(User.formatted_email(user))
    # |> subject("Réinitialisation du mot de passe Avril")
    # |> render_body("password.html", %{url: url, name: User.fullname(user)})
  end

  def confirmation(user, url) do
    user_email(
      "Confirmation de mon compte VAE sur Avril - la VAE facile",
      "confirmation.html",
      user,
      %{url: url}
    )
    # %Email{}
    # |> from(Coherence.Config.email_from)
    # |> to(User.formatted_email(user))
    # |> subject("Confirmation de mon compte VAE sur Avril - la VAE facile")
    # |> render_body("confirmation.html", %{url: url, name: User.fullname(user)})
  end

  def unlock(user, url) do
    user_email(
      "Débloquer votre compte Avril - la VAE facile",
      "unlock.html",
      user,
      %{url: url}
    )
    # %Email{}
    # |> from(Coherence.Config.email_from)
    # |> to(User.formatted_email(user))
    # |> subject("Débloquer votre compte Avril")
    # |> render_body("unlock.html", %{url: url, name: User.fullname(user)})
  end

  defp user_email(subject, template_name, user, params\\%{}) do
    %Email{}
    |> from(Coherence.Config.email_from)
    |> to(User.formatted_email(user))
    |> subject(subject)
    |> render_body(template_name, Map.merge(%{name: User.fullname(user)}, params))
  end
end
