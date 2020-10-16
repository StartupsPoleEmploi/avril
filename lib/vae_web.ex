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

      def put_assoc_if_present(%Ecto.Changeset{data: %struct{} = element} = changeset, key, params) do
        with(
          changeset <- %Ecto.Changeset{changeset | data: Repo.preload(element, key)},
          %{cardinality: cardinality, related: assoc_struct} <- struct.__schema__(:association, key),
          key_with_id <- key
            |> Atom.to_string()
            |> Inflex.singularize()
            |> String.replace_suffix("", "_id#{if cardinality == :many, do: "s"}")
            |> String.to_atom(),
          value when not is_nil(value) <- (params[key] || params[key_with_id])
        ) do
          case {cardinality, value} do
            {:one, id} when is_integer(id) -> Repo.get(assoc_struct, id)
            {:one, value}  -> value
            {:many, []} -> []
            {:many, [id | _rest] = list} when is_integer(id) -> Repo.all(from(e in assoc_struct, where: e.id in ^list))
            {:many, [%assoc_struct{} | _rest] = list} -> list
            _ -> nil
          end
          |> case do
            value when not is_nil(value) -> put_assoc(changeset, key, value)
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
