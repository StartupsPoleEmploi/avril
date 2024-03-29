defmodule VaeWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use VaeWeb, :controller
      use VaeWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """
  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      alias Vae.Repo

      def all, do: Vae.Repo.all(__MODULE__)

      def count_by_week(query, date_field) do
        query
        |> group_by([r], fragment("date_part('week', ?)", field(r, ^date_field)))
        |> select([r], [fragment("date_part('week', ?)", field(r, ^date_field)), count("*")])

        # TODO: sort by week number
        # TODO: add a year key
      end

      def is_active(query \\ __MODULE__) do
        if :is_active in __MODULE__.__schema__(:fields) do
          where(query, [q], q.is_active == true)
        else
          query
        end
      end

      def sort_by_popularity(query \\ __MODULE__) do
        # IO.inspect(query)

        # applications_query = from(a in UserApplication, select: count(a.id), where: a.certification_id == parent_as(:certification).id)

        # from(q in query,
        #   inner_lateral_join: c in subquery(applications_query), as: :count,
        #   order_by([desc: :count])
        # )
        # |> join(:inner_lateral_join, [q], c in subquery(applications_query), as: :count)
        query
        |> join(:left, [q], u in assoc(q, :applications))
        |> group_by([q, u], q.id)
        |> order_by([q, u], [desc: count(u.id)])
      end

      def put_assoc_no_useless_updates(changeset, key, value) do
        %Ecto.Changeset{changes: changes, data: data} = changeset = put_assoc(changeset, key, value)
        %{changeset | changes: Vae.Map.map_values(changes, fn {k, v} ->
          case v do
            v when is_list(v) ->
              Enum.reject(v, fn el ->
                case el do
                  %Ecto.Changeset{action: :update, changes: %{}, data: assoc} -> Enum.member?(Map.get(data, key), assoc)
                  _ -> false
                end
              end)
            v -> v
          end
        end) |> Enum.into(%{})}
      end

      def put_embed_if_necessary(changeset, params, key, _options \\ []) do
        klass_name = key |> Inflex.camelize() |> Inflex.singularize() |> String.to_atom()
        klass = [Elixir, Vae, klass_name] |> Module.concat()

        case params[key] do
          nil ->
            changeset

          values when is_list(values) ->
            put_embed(
              changeset,
              key,
              Enum.uniq_by(
                Map.get(changeset.data, key) ++ values,
                &klass.unique_key/1
              )
            )

          value ->
            put_embed(changeset, key, value)
        end
      end

      def put_param_assoc(%Ecto.Changeset{data: %struct{} = element} = changeset, key, params) do
        with(
          changeset <- %Ecto.Changeset{changeset | data: Repo.preload(element, key)},
          %{cardinality: cardinality, related: assoc_struct} <- struct.__schema__(:association, key),
          key_with_id <- key
            |> Atom.to_string()
            |> Inflex.singularize()
            |> String.replace_suffix("", "_id#{if cardinality == :many, do: "s"}")
            |> String.to_atom(),
          actual_key when not is_nil(actual_key) <- Enum.find([key, key_with_id], &Map.has_key?(params, &1)),
          value when not is_nil(value) <- params[actual_key]
        ) do
          case {cardinality, value} do
            {:one, id} when is_integer(id) or is_binary(id) -> Repo.get(assoc_struct, id)
            {:one, value}  -> value
            {:many, nil} -> []
            {:many, []} -> []
            {:many, [id | _rest] = list} when is_integer(id) or is_binary(id) -> Repo.all(from(e in assoc_struct, where: e.id in ^list))
            {:many, [%assoc_struct{} | _rest] = list} -> list
            _ -> nil
          end
          |> case do
            struct_value when not is_nil(struct_value) ->
              put_assoc(changeset, key, struct_value)
            nil -> changeset
          end
        else
          _ ->
            changeset
        end
      end
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: VaeWeb
      use Filterable.Phoenix.Controller

      alias Vae.Repo
      import Ecto
      import Ecto.Query

      import VaeWeb.Router.Helpers
      alias VaeWeb.Router.Helpers, as: Routes
      import VaeWeb.Gettext
      import VaeWeb.Controllers.Helpers
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/vae_web/templates", pattern: "**/*"

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, get_flash: 2, view_module: 1, current_path: 2]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Used in navbar.html.slim to preload association in the view
      alias Vae.Repo

      alias VaeWeb.Router.Helpers, as: Routes
      import VaeWeb.ErrorHelpers
      import VaeWeb.ViewHelpers
      import VaeWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Vae.Repo
      import Ecto
      import Ecto.Query
      import VaeWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
