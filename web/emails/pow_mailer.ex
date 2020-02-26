defmodule Vae.PowMailer do
  require Logger

  def cast(email) do
    {subject, template} = subject_to_template(email.subject)
    Vae.Mailer.build_email(template, :avril, email.user, Map.merge(%{
      subject: subject,
      name: Vae.User.fullname(email.user)
    }, Enum.into(email.assigns, %{})))
  end

  def process(email), do: Vae.Mailer.send(email)

  defp subject_to_template(pow_subject) do
    case pow_subject do
      "Confirm your email address" -> {"Merci de confirmer votre adresse email sur Avril, la VAE facile", "user/confirmation.html"}
      "Reset password link" -> {"Réinitialiser son mot de passe Avril, la VAE facile", "user/password.html"}
    end
  end
end
