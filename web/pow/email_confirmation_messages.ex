defmodule Vae.Pow.Messages.PowEmailConfirmation.Phoenix.Messages do
    @moduledoc """
  Module that handles messages for PowEmailConfirmation.
  See `Pow.Extension.Phoenix.Messages` for more.
  """

  @doc """
  Flash message to show when email has been confirmed.
  """
  def confirmation_email_has_been_resent(_conn), do: "Un email de confirmation vous a été renvoyé."

  @doc """
  Flash message to show when email has been confirmed.
  """
  def email_has_been_confirmed(_conn), do: "L'adresse email a bien été confirmée."

  @doc """
  Flash message to show when email couldn't be confirmed.
  """
  def email_confirmation_failed(_conn), do: "L'adresse email n'a pas pu être confirmée."

  @doc """
  Flash message to show when user is signs in or registers but e-mail is yet
  to be confirmed.
  """
  def email_confirmation_required(_conn), do: "Vous devez d'abord confirmer votre adresse email."

  @doc """
  Flash message to show when user updates their e-mail and requires
  confirmation.
  """
  def email_confirmation_required_for_update(_conn), do: "Vous devez d'abord confirmer votre adresse email."
end