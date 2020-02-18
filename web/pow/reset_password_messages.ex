defmodule Vae.Pow.Messages.PowResetPassword.Phoenix.Messages do
  @moduledoc """
  Module that handles messages for PowResetPassword.
  See `Pow.Extension.Phoenix.Messages` for more.
  """

  @doc """
  Flash message to show generic response for reset password request.
  """
  def maybe_email_has_been_sent(_conn), do: "Nous vous avons envoyé un lien de réinitialisation par email. Merci de vérifier votre boîte de réception."

  @doc """
  Flash message to show when a reset password e-mail has been sent. Falls back
  to `maybe_email_has_been_sent/1`
  """
  def email_has_been_sent(conn), do: maybe_email_has_been_sent(conn)

  @doc """
  Flash message to show when no user exists for the provided e-mail.
  """
  def user_not_found(_conn), do: "Pas de compte associé à cette adresse"

  @doc """
  Flash message to show when a an invalid or expired reset password link is
  used.
  """
  def invalid_token(_conn), do: "Le lien envoyé par email a expiré. Merci de refaire une demande"

  @doc """
  Flash message to show when password has been updated.
  """
  def password_has_been_reset(_conn), do: "Le mot de passe a bien été mis à jour."
end