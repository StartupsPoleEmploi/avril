defmodule VaeWeb.CertificationView do
  use VaeWeb, :view
  use Scrivener.HTML
  alias Vae.Certification

  def split_intro(%Certification{activities: activities}) do
    [intro, rest] = activities
    |> String.replace(~r/<br\s*\/?>/i, "</p><p>", global: false)
    |> String.split("</p>", parts: 2)

    {"#{intro}</p>", rest}
  end

  def render_steps(process, opts \\ []) do
    process
    |> Map.take(Enum.map(1..8, &:"step_#{&1}"))
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
    |> Enum.map(fn {k, step} ->
      i = k |> Atom.to_string() |> String.at(5) |> String.to_integer()

      content_tag(
        :div,
        [step_title(i), raw(step)],
        class: Keyword.get(opts, :step_class, step_class(i)),
        id: "step_#{i}"
      )
    end)
  end

  def step_class(1), do: ""
  def step_class(_), do: "d-none"

  def step_title(number) do
    content_tag(
      :h6,
      [
        content_tag(:span, Integer.to_string(number), class: "dm-step"),
        content_tag(:span, "#{ordinal_number(number)} étape", class: "dm-step-sub")
      ],
      class: "d-flex"
    )
  end

  def ordinal_number(1), do: "ère"
  def ordinal_number(2), do: "nde"
  def ordinal_number(_), do: "ème"

  def render_contact_form_data(conn, delegate, certification) do
    {:safe,
     """
     <script>
     window.delegate = #{delegate.id}
     window.profession = "#{Plug.Conn.get_session(conn, :search_profession)}"
     window.certification = "#{Vae.Certification.name(certification)}"
     window.county = "#{Plug.Conn.get_session(conn, :search_county)}"
     </script>
     """}
  end
end
