defmodule Vae.ExAdmin.Helpers do
  use Xain
  import Phoenix.HTML.Tag
  alias Vae.Repo

  def resource_name(resource, namify \\ nil) do
      cond do
        namify ->
          namify.(resource)

        Keyword.has_key?(resource.__struct__.__info__(:functions), :name) ->
          resource.__struct__.name(resource)

        Map.has_key?(Map.from_struct(resource.__struct__), :name) ->
          resource.name

        true ->
          resource.id
      end

  end

  def resource_name_and_link(resource, opts \\ [])
  def resource_name_and_link(nil, _opts), do: nil

  def resource_name_and_link(resource, opts) do
    name = resource_name(resource, opts[:namify])

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

  def form_select_tag(%struct{} = object, association_name, options \\ nil) do
    object = Repo.preload(object, association_name)

    association_struct = struct.__schema__(:association, association_name).related
    label = options[:label] || (association_name |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize())
    possible_options = options[:options] || Repo.all(association_struct)

    options =
      possible_options
      |> Enum.sort_by(&(resource_name(&1, options[:namify])))
      |> Enum.map(fn asso ->
        content_tag(:option, resource_name(asso, options[:namify]), [
          value: asso.id,
          selected: Enum.member?(Map.get(object, association_name), asso)
        ])
      end)

    object_name = object.__struct__ |> Atom.to_string() |> String.split(".") |> List.last() |> String.downcase()
    # association_name_ids = association_name |> Atom.to_string() # |> String.replace_suffix("s", "_ids")

    content_tag(
      :div,
      [
        content_tag(
          :label,
          label,
          class: "col-sm-2 control-label"
        ),
        content_tag(
          :div,
          [
            Phoenix.HTML.Form.hidden_input(String.to_atom(object_name), association_name, id: "fake_#{object_name}_#{association_name}"),
            content_tag(
              :select,
              options,
              id: "#{object_name}_#{association_name}",
              name: "#{object_name}[#{association_name}][]",
              multiple: true
            )
          ],
          class: "col-sm-10"
        )
      ],
      class: "form-group"
    )
  end
end
