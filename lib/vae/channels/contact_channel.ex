defmodule Vae.ContactChannel do
  use Phoenix.Channel

  def join("contact:*", _message, socket) do
    {:ok, socket}
  end
end
