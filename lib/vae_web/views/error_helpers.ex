defmodule VaeWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  # def error_tag(errors, field) when is_list(errors) and is_atom(field) do
  #   case Keyword.fetch(errors, field) do
  #     {:ok, message} -> content_tag :span, (humanize(field) <> " " <> translate_error(message)), class: "help-block"
  #     :error -> html_escape("")
  #   end
  # end

  def form_field_error(form, field) do
    Enum.find(form.source.errors, fn {k, v} -> k == field end)
  end

  def error_tag(form, field) do
    if error = form_field_error(form, field) do
      content_tag(:p, translate_error(elem(error, 1)), class: "help is-danger")
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(VaeWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(VaeWeb.Gettext, "errors", msg, opts)
    end
  end
end
