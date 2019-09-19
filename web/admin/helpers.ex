defmodule Vae.ExAdmin.Helpers do
  alias Vae.Router.Helpers, as: Routes

  def link_to_resource(resource, opts\\[]) do
    name = cond do
      opts[:namify] -> opts[:namify].(resource)
      Keyword.has_key?(resource.__struct__.__info__(:functions), :name) ->
        resource.__struct__.name(resource)
      true -> resource.name
    end
    Phoenix.HTML.Link.link(name, to:  ExAdmin.Utils.admin_resource_path(resource))
  end
end