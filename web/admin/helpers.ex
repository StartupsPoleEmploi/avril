defmodule Vae.ExAdmin.Helpers do
  use Xain

  def resource_name_and_link(resource, opts \\ [])
  def resource_name_and_link(nil, _opts), do: nil
  def resource_name_and_link(resource, opts) do
    name = cond do
      opts[:namify] -> opts[:namify].(resource)
      Keyword.has_key?(resource.__struct__.__info__(:functions), :name) ->
        resource.__struct__.name(resource)
      true -> resource.name
    end
    path = ExAdmin.Utils.admin_resource_path(resource)
    {name, path}
  end

  def path_to_url(path), do: "#{Vae.Endpoint.static_url}#{path}"

  def link_to_resource(resource, opts \\ []) do
    {name, path} = link_to_resource(resource, opts)
    Phoenix.HTML.Link.link(name, to:  path_to_url(path))
  end

  def csv_link_to_resource(resource, opts) do
    {name, path} = link_to_resource(resource, opts)
    "=HYPERLINK(\"#{path}\";\"#{name}\")"
  end

  def print_in_json(nil), do: nil
  def print_in_json(data) do
    markup do
      pre(Jason.encode!(Map.from_struct(data), pretty: true))
    end
  end
end