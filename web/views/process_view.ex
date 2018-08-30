defmodule Vae.ProcessView do
  use Vae.Web, :view
  alias Phoenix.HTML
  alias Phoenix.HTML.{Link, Tag}

  def render_contact(delegate) do
    case delegate.email do
      nil ->
        Link.link(
          "Prendre contact",
          to: delegate.website,
          class: "btn btn-primary btn-block no-print",
          target: "_blank"
        )

      _ ->
        Link.link(
          "Prendre contact",
          to: "mailto:#{delegate.email}",
          class: "btn btn-primary btn-block no-print"
        )
    end
  end

  def render_steps(process) do
    process
    |> Map.take(Enum.map(1..8, &:"step_#{&1}"))
    |> Enum.filter(fn {k, v} -> not is_nil(v) end)
    |> Enum.map(fn {k, step} ->
      i = k |> Atom.to_string() |> String.at(5) |> String.to_integer()

      class =
        case i do
          1 -> ""
          _ -> "d-none"
        end

      Tag.content_tag(
        :div,
        [step_title(i), HTML.raw(step)],
        class: class,
        id: "step_#{i}"
      )
    end)
  end

  def step_title(number) do
    Tag.content_tag(
      :h6,
      [
        Tag.content_tag(:span, Integer.to_string(number), class: "dm-step"),
        Tag.content_tag(:span, "#{ordinal_number(number)} étape", class: "dm-step-sub")
      ],
      class: "d-flex"
    )
  end

  def ordinal_number(number) do
    case number do
      1 -> "ère"
      2 -> "nde"
      _ -> "ème"
    end
  end
end
