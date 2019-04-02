defmodule Vae.LayoutView do
  use Vae.Web, :view

  alias Vae.ComponentView

  def base_layout(conn, do: contents) do
    render "base.html", [conn: conn, contents: contents]
  end
end
