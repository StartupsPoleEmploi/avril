defmodule Vae.LayoutView do
  use Vae.Web, :view

  alias Vae.ComponentView

  def base_layout(conn, assigns, do: contents) do
    render "_base.html", [conn: conn, assigns: assigns, contents: contents]
  end
end
