defmodule Vae.CertificationView do
  use Vae.Web, :view
  use Scrivener.HTML

  def to_delegate(conn, certification, nil) do
    if is_nil(Plug.Conn.get_session(conn, :search_lat)) ||
         is_nil(Plug.Conn.get_session(conn, :search_lng)) do
      Routes.delegate_path(conn, :index, diplome: certification)
    else
      Routes.certification_path(
        conn,
        :show,
        certification
      )
    end
  end

  def to_delegate(conn, certification, delegate) do
    Routes.certification_path(
      conn,
      :show,
      certification,
      certificateur: delegate
    )
  end

  def to_delegate_label(conn, nil) do
    if is_nil(Plug.Conn.get_session(conn, :search_lat)) ||
         is_nil(Plug.Conn.get_session(conn, :search_lng)) do
      "Les certificateurs"
    else
      "Étapes VAE"
    end
  end

  def to_delegate_label(_conn, _delegate), do: "Étapes VAE"

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
     window.certification = "#{format_certification_label(certification)}"
     window.county = "#{Plug.Conn.get_session(conn, :search_county)}"
     </script>
     """}
  end
end
