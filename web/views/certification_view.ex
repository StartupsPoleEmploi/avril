defmodule Vae.CertificationView do
  use Vae.Web, :view
  use Scrivener.HTML

  def link_certification_to(conn, certification, nil) do
    if not (is_nil(Plug.Conn.get_session(conn, :search_lat)) ||
              is_nil(Plug.Conn.get_session(conn, :search_lng))) do
      certification_path(
        conn,
        :show,
        certification
      )
    else
      delegate_path(conn, :index, diplome: certification)
    end
  end

  def link_certification_to(conn, certification, delegate) do
    certification_path(
      conn,
      :show,
      certification,
      certificateur: delegate
    )
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
     window.certification = "#{certification.acronym} #{String.downcase(certification.label)}"
     window.county = "#{Plug.Conn.get_session(conn, :search_county)}"
     </script>
     """}
  end
end
