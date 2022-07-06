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

  def readable_changeset(%Ecto.Changeset{data: data, action: action} = change) do
    field = if Map.has_key?(data, :slug), do: :slug, else: :id
    "#{Ecto.Changeset.fetch_field!(change, field)} (#{action})"
  end

  def readable_changes(changes) do
    Enum.map(changes, fn {key, value} ->
      readable_value = case value do
        %Ecto.Changeset{} = assoc_changes -> readable_changeset(assoc_changes)
        [%Ecto.Changeset{} | _] = assoc_changes ->
          Enum.map(assoc_changes, &readable_changeset(&1))
          |> Enum.sort_by(&(&1))
        anything -> anything
      end
      {key, readable_value}
    end)
    |> Map.new()
  end

  def calc_diffs(changes, field, current_value) do
    case Map.get(changes, field) do
      new_value when is_list(new_value) ->
        new_value_no_operations = Enum.map(new_value, &String.trim(Regex.replace(~r/\([a-z]+\)/, &1, "")))
        changes
        |> Map.delete(field)
        |> Map.put("current_#{field}", current_value)
        |> Map.put("new_#{field}", new_value)
        |> Map.put("diff_#{field}", %{
          add: new_value_no_operations -- current_value,
          remove: current_value -- new_value_no_operations
        })
      _ -> changes
    end
  end

  def print_in_json(nil), do: nil

  def print_in_json(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> print_in_json()
  end

  def print_in_json(anything) do
    markup do
      anything
      |> Poison.encode!(pretty: true)
      |> pre()
      |> Phoenix.HTML.raw()
    end
  end

  def form_select_tag(%struct{} = object, association_name, options \\ []) do
    object = Repo.preload(object, association_name)

    association_struct = struct.__schema__(:association, association_name).related
    label = options[:label] || (struct_to_string(association_struct) |> Vae.String.pluralize())
    possible_options = options[:options] || Repo.all(association_struct)

    select_options =
      possible_options
      |> Enum.sort_by(&(resource_name(&1, options[:namify])))
      |> Enum.map(fn asso ->
        content_tag(:option, resource_name(asso, options[:namify]), [
          value: asso.id,
          selected: Enum.member?(Map.get(object, association_name) |> Enum.map(&(&1.id)), asso.id)
        ])
      end)

    object_name = object.__struct__ |> struct_to_string() |> String.downcase()
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
              select_options,
              id: "#{object_name}_#{association_name}",
              name: "#{object_name}[#{association_name}][]",
              multiple: true,
              data: [
                selectable: options[:selectable_label] || "All possible #{String.downcase(label)}",
                selection: options[:selection_label] || "Selected #{String.downcase(label)}"
              ]
            )
          ],
          class: "col-sm-10"
        )
      ],
      class: "form-group"
    )
  end

  def count_and_link_to_all(%struct{} = object, association_name, options \\ []) do
    object = Repo.preload(object, association_name)
    struct_name = struct |> struct_to_string()
    association_struct = struct.__schema__(:association, association_name).related
    label = options[:label] || struct_to_string(association_struct)

    Phoenix.HTML.Link.link("#{Vae.String.inflect(length(Map.get(object, association_name)), label)}", to: VaeWeb.Router.Helpers.admin_resource_path(Vae.URI.endpoint(), :index, Inflex.underscore(Inflex.pluralize(struct_to_string(association_struct))), %{"q[#{String.downcase(struct_name)}_id_eq]" => object.id}))
  end

  def struct_to_string(struct) do
    struct |> Atom.to_string() |> String.split(".") |> List.last()
  end
end

defimpl Poison.Encoder, for: Tuple do
  def encode(data, options) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> Poison.Encoder.List.encode(options)
  end
end