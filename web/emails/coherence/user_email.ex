defmodule Vae.Coherence.UserEmail do
  alias Vae.Mailer
  alias Vae.User

  def password(user, url) do
    Mailer.build_email(
      "user/password.html",
      :avril,
      user,
      %{
        subject: "Réinitialisation du mot de passe sur Avril - la VAE facile",
        name: User.fullname(user),
        url: url
      }
    )
  end

  def confirmation(user, url) do
    Mailer.build_email(
      "user/confirmation.html",
      :avril,
      user,
      %{
        subject: "Confirmation de mon compte VAE sur Avril - la VAE facile",
        url: url
      }
    )
  end

  def unlock(user, url) do
    Mailer.build_email(
      "user/unlock.html",
      :avril,
      user,
      %{
        subject: "Débloquer votre compte Avril - la VAE facile",
        url: url
      }
    )
  end
end
