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
