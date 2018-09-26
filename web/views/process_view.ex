defmodule Vae.ProcessView do
  use Vae.Web, :view
  alias Phoenix.HTML
  alias Phoenix.HTML.{Link, Tag}

  def render_steps(process, opts \\ []) do
    process
    |> Map.take(Enum.map(1..8, &:"step_#{&1}"))
    |> Enum.filter(fn {k, v} -> not is_nil(v) end)
    |> Enum.map(fn {k, step} ->
      i = k |> Atom.to_string() |> String.at(5) |> String.to_integer()

      Tag.content_tag(
        :div,
        [step_title(i), HTML.raw(step)],
        class: Keyword.get(opts, :step_class, step_class(i)),
        id: "step_#{i}"
      )
    end)
  end

  def step_class(1), do: ""
  def step_class(_), do: "d-none"

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

  def ordinal_number(1), do: "ère"
  def ordinal_number(2), do: "nde"
  def ordinal_number(_), do: "ème"

  def render_contact_form_data(conn, delegate, certification) do
    {:safe,
     """
     <script>
     window.delegate_city = "#{Vae.Places.get_city(delegate.geolocation)}"
     window.delegate_name = "#{delegate.name}"
     window.delegate_email = "#{delegate.email}"
     window.delegate_address = "#{delegate.address}"
     window.delegate_phone_number = "#{delegate.telephone}"
     window.job = "#{Plug.Conn.get_session(conn, :search_job)}"
     window.certification = "#{certification.acronym} #{String.downcase(certification.label)}"
     window.process = #{delegate.process.id}
     </script>
     """}
  end
end
