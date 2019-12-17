defmodule Vae.ExAdmin.Helpers do
  use Xain

  def link_to_resource(resource, opts \\ [])
  def link_to_resource(nil, _opts), do: nil
  def link_to_resource(resource, opts) do
    name = cond do
      opts[:namify] -> opts[:namify].(resource)
      Keyword.has_key?(resource.__struct__.__info__(:functions), :name) ->
        resource.__struct__.name(resource)
      true -> resource.name
    end
    Phoenix.HTML.Link.link(name, to:  ExAdmin.Utils.admin_resource_path(resource))
  end

  def print_in_json(nil), do: nil
  def print_in_json(data) do
    markup do
      pre(Jason.encode!(Map.from_struct(data), pretty: true))
    end
  end
end