Code.ensure_loaded Phoenix.Swoosh

defmodule Vae.Coherence.UserEmail do
  @moduledoc false
  require Logger
  use Phoenix.Swoosh,
    view: Vae.Coherence.EmailView,
    layout: {Vae.Coherence.LayoutView, :email}
  alias Swoosh.Email
  # alias Coherence.Config
  alias Vae.User

  def password(user, url) do
    user_email(
      "Réinitialisation du mot de passe sur Avril - la VAE facile",
      "password.html",
      user,
      %{url: url}
    )
  end

  def confirmation(user, url) do
    user_email(
      "Confirmation de mon compte VAE sur Avril - la VAE facile",
      "confirmation.html",
      user,
      %{url: url}
    )
  end

  def unlock(user, url) do
    user_email(
      "Débloquer votre compte Avril - la VAE facile",
      "unlock.html",
      user,
      %{url: url}
    )
  end

  defp user_email(subject, template_name, user, params\\%{}) do
    %Email{}
    |> from(Coherence.Config.email_from)
    |> to(User.formatted_email(user))
    |> subject(subject)
    |> render_body(template_name, Map.merge(%{name: User.fullname(user)}, params))
  end
end
