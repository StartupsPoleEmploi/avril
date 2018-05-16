defmodule Vae.ProcessView do

  use Vae.Web, :view

  def render_contact(delegate) do
    case delegate.email do
      nil ->
         Phoenix.HTML.Link.link(
          "Prendre contact",
          to: delegate.website,
          class: "btn btn-primary btn-block no-print",
          target: "_blank"
        )
      _->
        Phoenix.HTML.Link.link(
          "Prendre contact",
          to: "mailto:#{delegate.email}",
          class: "btn btn-primary btn-block no-print"
        )
    end
  end
end
