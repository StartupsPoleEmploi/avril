defmodule Vae.ExAdmin.Helpers do
  use Xain

  def resource_name_and_link(resource, opts \\ [])
  def resource_name_and_link(nil, _opts), do: nil

  def resource_name_and_link(resource, opts) do
    name =
      cond do
        opts[:namify] ->
          opts[:namify].(resource)

        Keyword.has_key?(resource.__struct__.__info__(:functions), :name) ->
          resource.__struct__.name(resource)

        Map.has_key?(Map.from_struct(resource.__struct__), :name) ->
          resource.name

        true ->
          resource.id
      end

    path = ExAdmin.Utils.admin_resource_path(resource)
    {csv_espace(name), path}
  end

  def path_to_url(path), do: "#{VaeWeb.Endpoint.static_url()}#{path}"

  def link_to_resource(resource, opts \\ []) do
    case resource_name_and_link(resource, opts) do
      nil -> nil
      {name, path} -> Phoenix.HTML.Link.link(name, to: path)
    end
  end

  def csv_link_to_resource(resource, opts \\ []) do
    case resource_name_and_link(resource, opts) do
      nil -> nil
      # {name, path} -> "[[hyperlink URL link=#{path_to_url(path)} display=#{name}]]"
      {name, path} -> "=HYPERLINK(\"#{path_to_url(path)}\",\"#{name}\")"
    end
  end

  def csv_espace(string) when is_binary(string) do
    string |> String.replace(~r/\"/, "\"\"")
  end
  def csv_espace(other), do: other

  def print_in_json(nil), do: nil

  def print_in_json(data) do
    markup do
      pre(Jason.encode!(Map.from_struct(data), pretty: true))
    end
  end
end
