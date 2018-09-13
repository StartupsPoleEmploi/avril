defmodule Vae.ContactChannel do
  use Phoenix.Channel

  def join("contact:send", _message, socket) do
    {:ok, socket}
  end

  def handle_in("contact_request", %{"body" => body}, socket) do
    body |> IO.inspect()
    {:reply, {:ok, %{}}, socket}
  end
end
