defmodule Vae.Pow.Messages do
  use Pow.Phoenix.Messages

  @doc """
  Message for when user is not authenticated.

  Defaults to nil.
  """
  def user_not_authenticated(_conn), do: nil

  @doc """
  Message for when user is already authenticated.

  Defaults to nil.
  """
  def user_already_authenticated(_conn), do: nil

  @doc """
  Message for when user has signed in.

  Defaults to nil.
  """
  def signed_in(_conn), do: nil

  @doc """
  Message for when user has signed out.

  Defaults to nil.
  """
  def signed_out(_conn), do: nil

  @doc """
  Message for when user couldn't be signed in.
  """
  def invalid_credentials(_conn),
    do: "Email/mot de passe incorrect. Merci de réessayer."

  @doc """
  Message for when user has signed up successfully.

  Defaults to nil.
  """
  def user_has_been_created(_conn), do: nil

  @doc """
  Message for when user has updated their account successfully.
  """
  def user_has_been_updated(_conn), do: "Enregistré."

  @doc """
  Message for when user has deleted their account successfully.
  """
  def user_has_been_deleted(_conn), do: "Votre compte a bien été supprimé. Au revoir !"

  @doc """
  Message for when account could not be deleted.
  """
  def user_could_not_be_deleted(_conn), do: "Votre compte n'a pas pu être supprimé. Merci de nous contacter."

end
